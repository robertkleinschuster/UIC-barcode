import Foundation

/// Non-UIC ticket data
/// Java ref: SsbNonUic.java
public struct SSBNonUic {
    public var data: Data

    public init(bitBuffer: BitBuffer) throws {
        // Read remaining bits as raw data (from after header to signature)
        var buffer = bitBuffer
        let headerBits = 27
        let signatureBitOffset = SSBFrame.signatureOffset * 8
        let remainingBytes = (signatureBitOffset - headerBits) / 8
        try buffer.seek(to: headerBits)
        data = try buffer.getBytes(remainingBytes)
    }
}

// MARK: - SSBNonUic Encoding

extension SSBNonUic {

    /// Encode non-UIC data into the bit buffer.
    func encode(to bitBuffer: inout BitBuffer) throws {
        // Write raw data bytes after header (27 bits)
        let startByte = 27 / 8 + (27 % 8 == 0 ? 0 : 1) // byte 4
        let endByte = min(startByte + data.count, SSBFrame.signatureOffset)
        for i in 0..<(endByte - startByte) {
            guard i < data.count else { break }
            // Write byte-by-byte using putInteger at bit offset
            let bitOffset = (startByte + i) * 8
            try bitBuffer.putInteger(Int(data[i]), at: bitOffset, length: 8)
        }
    }
}
