import Foundation

/// Parser for DER-encoded ASN.1 structures
public struct DERParser {
    private var data: Data
    private var position: Int = 0

    public init(data: Data) {
        self.data = data
    }

    /// Parse SubjectPublicKeyInfo to extract the public key bytes
    public mutating func parseSubjectPublicKeyInfo() throws -> Data {
        // SEQUENCE { AlgorithmIdentifier, BIT STRING }
        _ = try expectTag(0x30) // SEQUENCE
        _ = try readLength()

        // AlgorithmIdentifier
        _ = try expectTag(0x30) // SEQUENCE
        let algIdLength = try readLength()
        position += algIdLength // Skip algorithm identifier

        // BIT STRING containing the public key
        _ = try expectTag(0x03) // BIT STRING
        let bitStringLength = try readLength()

        // First byte of BIT STRING is the number of unused bits (usually 0)
        let unusedBits = data[position]
        position += 1

        guard unusedBits == 0 else {
            throw UICBarcodeError.invalidPublicKey("Unexpected unused bits in BIT STRING")
        }

        // Remaining bytes are the public key
        let keyLength = bitStringLength - 1
        guard position + keyLength <= data.count else {
            throw UICBarcodeError.invalidPublicKey("Insufficient data for public key")
        }

        let keyData = Data(data[position..<(position + keyLength)])
        return keyData
    }

    /// Parse a certificate to extract the public key
    public mutating func parseCertificatePublicKey() throws -> Data {
        // TBSCertificate is wrapped in SEQUENCE
        _ = try expectTag(0x30) // Certificate SEQUENCE
        _ = try readLength()

        _ = try expectTag(0x30) // TBSCertificate SEQUENCE
        _ = try readLength()

        // Skip version (context tag [0])
        if peekTag() == 0xA0 {
            _ = try expectTag(0xA0)
            let versionLength = try readLength()
            position += versionLength
        }

        // Skip serialNumber (INTEGER)
        _ = try expectTag(0x02)
        let serialLength = try readLength()
        position += serialLength

        // Skip signature AlgorithmIdentifier (SEQUENCE)
        _ = try expectTag(0x30)
        let sigAlgLength = try readLength()
        position += sigAlgLength

        // Skip issuer (SEQUENCE)
        _ = try expectTag(0x30)
        let issuerLength = try readLength()
        position += issuerLength

        // Skip validity (SEQUENCE)
        _ = try expectTag(0x30)
        let validityLength = try readLength()
        position += validityLength

        // Skip subject (SEQUENCE)
        _ = try expectTag(0x30)
        let subjectLength = try readLength()
        position += subjectLength

        // SubjectPublicKeyInfo - this is what we want
        return try parseSubjectPublicKeyInfo()
    }

    /// Parse an OBJECT IDENTIFIER
    public mutating func parseObjectIdentifier() throws -> String {
        _ = try expectTag(0x06) // OID tag
        let length = try readLength()

        guard position + length <= data.count else {
            throw UICBarcodeError.invalidData("Insufficient data for OID")
        }

        var components = [UInt64]()
        var accumulator: UInt64 = 0

        for i in 0..<length {
            let byte = data[position + i]
            accumulator = (accumulator << 7) | UInt64(byte & 0x7F)

            if (byte & 0x80) == 0 {
                if components.isEmpty {
                    // First byte encodes first two components
                    components.append(accumulator / 40)
                    components.append(accumulator % 40)
                } else {
                    components.append(accumulator)
                }
                accumulator = 0
            }
        }

        position += length
        return components.map { String($0) }.joined(separator: ".")
    }

    /// Parse an INTEGER
    public mutating func parseInteger() throws -> Data {
        _ = try expectTag(0x02) // INTEGER tag
        let length = try readLength()

        guard position + length <= data.count else {
            throw UICBarcodeError.invalidData("Insufficient data for INTEGER")
        }

        let intData = Data(data[position..<(position + length)])
        position += length
        return intData
    }

    /// Parse an OCTET STRING
    public mutating func parseOctetString() throws -> Data {
        _ = try expectTag(0x04) // OCTET STRING tag
        let length = try readLength()

        guard position + length <= data.count else {
            throw UICBarcodeError.invalidData("Insufficient data for OCTET STRING")
        }

        let octets = Data(data[position..<(position + length)])
        position += length
        return octets
    }

    /// Parse a BIT STRING
    public mutating func parseBitString() throws -> (unusedBits: UInt8, data: Data) {
        _ = try expectTag(0x03) // BIT STRING tag
        let length = try readLength()

        guard position + length <= data.count, length > 0 else {
            throw UICBarcodeError.invalidData("Insufficient data for BIT STRING")
        }

        let unusedBits = data[position]
        position += 1

        let bits = Data(data[position..<(position + length - 1)])
        position += length - 1

        return (unusedBits, bits)
    }

    // MARK: - DSA Key Parsing

    /// Parse a DSA SubjectPublicKeyInfo structure
    /// Format: SEQUENCE { SEQUENCE { OID, SEQUENCE { INTEGER p, INTEGER q, INTEGER g } }, BIT STRING { INTEGER y } }
    public mutating func parseDSAPublicKeyInfo() throws -> (params: (p: Data, q: Data, g: Data), y: Data) {
        _ = try expectTag(0x30) // Outer SEQUENCE
        _ = try readLength()

        // AlgorithmIdentifier SEQUENCE
        _ = try expectTag(0x30)
        _ = try readLength()

        // OID
        let oid = try parseObjectIdentifier()
        guard oid == "1.2.840.10040.4.1" else {
            throw UICBarcodeError.invalidPublicKey("Expected DSA OID (1.2.840.10040.4.1), got \(oid)")
        }

        // DSS-Params SEQUENCE
        let params = try parseDSAParameters()

        // BIT STRING containing INTEGER y
        let bitString = try parseBitString()
        guard bitString.unusedBits == 0 else {
            throw UICBarcodeError.invalidPublicKey("Unexpected unused bits in DSA public key BIT STRING")
        }

        // Parse the INTEGER y from the bit string content
        var yParser = DERParser(data: bitString.data)
        let y = try yParser.parseInteger()

        return (params, y)
    }

    /// Parse DSS-Params: SEQUENCE { INTEGER p, INTEGER q, INTEGER g }
    public mutating func parseDSAParameters() throws -> (p: Data, q: Data, g: Data) {
        _ = try expectTag(0x30) // SEQUENCE
        _ = try readLength()

        let p = try parseInteger()
        let q = try parseInteger()
        let g = try parseInteger()

        return (p, q, g)
    }

    /// Parse a certificate to extract DSA public key parameters
    public mutating func parseCertificateDSAPublicKey() throws -> (params: (p: Data, q: Data, g: Data), y: Data) {
        // Certificate SEQUENCE
        _ = try expectTag(0x30)
        _ = try readLength()

        // TBSCertificate SEQUENCE
        _ = try expectTag(0x30)
        _ = try readLength()

        // Skip version (context tag [0])
        if peekTag() == 0xA0 {
            _ = try expectTag(0xA0)
            let versionLength = try readLength()
            position += versionLength
        }

        // Skip serialNumber (INTEGER)
        _ = try expectTag(0x02)
        let serialLength = try readLength()
        position += serialLength

        // Skip signature AlgorithmIdentifier (SEQUENCE)
        _ = try expectTag(0x30)
        let sigAlgLength = try readLength()
        position += sigAlgLength

        // Skip issuer (SEQUENCE)
        _ = try expectTag(0x30)
        let issuerLength = try readLength()
        position += issuerLength

        // Skip validity (SEQUENCE)
        _ = try expectTag(0x30)
        let validityLength = try readLength()
        position += validityLength

        // Skip subject (SEQUENCE)
        _ = try expectTag(0x30)
        let subjectLength = try readLength()
        position += subjectLength

        // SubjectPublicKeyInfo - parse as DSA
        return try parseDSAPublicKeyInfo()
    }

    /// Extract algorithm OID from a SubjectPublicKeyInfo structure
    public mutating func extractAlgorithmOID() throws -> String {
        _ = try expectTag(0x30) // Outer SEQUENCE
        _ = try readLength()

        // AlgorithmIdentifier SEQUENCE
        _ = try expectTag(0x30)
        _ = try readLength()

        // OID
        return try parseObjectIdentifier()
    }

    // MARK: - Private Helpers

    private func peekTag() -> UInt8? {
        guard position < data.count else { return nil }
        return data[position]
    }

    private mutating func expectTag(_ expected: UInt8) throws -> UInt8 {
        guard position < data.count else {
            throw UICBarcodeError.invalidData("Unexpected end of DER data")
        }

        let tag = data[position]
        guard tag == expected else {
            throw UICBarcodeError.invalidData("Expected tag \(String(format: "0x%02X", expected)), got \(String(format: "0x%02X", tag))")
        }

        position += 1
        return tag
    }

    private mutating func readLength() throws -> Int {
        guard position < data.count else {
            throw UICBarcodeError.invalidData("Unexpected end of DER data while reading length")
        }

        let firstByte = data[position]
        position += 1

        if (firstByte & 0x80) == 0 {
            // Short form: length is in the first byte
            return Int(firstByte)
        } else {
            // Long form: first byte indicates number of length bytes
            let numLengthBytes = Int(firstByte & 0x7F)

            guard numLengthBytes <= 4 else {
                throw UICBarcodeError.invalidData("Length too large")
            }

            guard position + numLengthBytes <= data.count else {
                throw UICBarcodeError.invalidData("Insufficient data for length bytes")
            }

            var length = 0
            for _ in 0..<numLengthBytes {
                length = (length << 8) | Int(data[position])
                position += 1
            }

            return length
        }
    }

    // MARK: - DER Builder (Static Methods)

    /// Build a DER-encoded signature from raw r and s integer values.
    public static func buildDERSignature(r: Data, s: Data) -> Data {
        let rEncoded = buildDERInteger(r)
        let sEncoded = buildDERInteger(s)
        let sequenceContent = rEncoded + sEncoded
        return buildDERSequence(sequenceContent)
    }

    /// Build a DER-encoded INTEGER from raw bytes.
    /// Adds leading zero if high bit is set (positive integer convention).
    public static func buildDERInteger(_ value: Data) -> Data {
        var bytes = value
        // Strip leading zeros (but keep at least one byte)
        while bytes.count > 1 && bytes[0] == 0 {
            bytes = bytes.dropFirst()
        }
        // Add leading zero if high bit is set
        if !bytes.isEmpty && (bytes[0] & 0x80) != 0 {
            var padded = Data([0x00])
            padded.append(bytes)
            bytes = padded
        }
        var result = Data()
        result.append(0x02) // INTEGER tag
        result.append(contentsOf: encodeDERLength(bytes.count))
        result.append(bytes)
        return result
    }

    /// Build a DER SEQUENCE wrapper around content.
    public static func buildDERSequence(_ content: Data) -> Data {
        var result = Data()
        result.append(0x30) // SEQUENCE tag
        result.append(contentsOf: encodeDERLength(content.count))
        result.append(content)
        return result
    }

    /// Encode a DER length value.
    public static func encodeDERLength(_ length: Int) -> [UInt8] {
        if length < 128 {
            return [UInt8(length)]
        } else if length <= 0xFF {
            return [0x81, UInt8(length)]
        } else if length <= 0xFFFF {
            return [0x82, UInt8(length >> 8), UInt8(length & 0xFF)]
        } else {
            return [0x83, UInt8(length >> 16), UInt8((length >> 8) & 0xFF), UInt8(length & 0xFF)]
        }
    }
}
