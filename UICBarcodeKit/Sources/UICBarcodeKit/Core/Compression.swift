import Foundation
import Compression

/// Utilities for DEFLATE compression/decompression used in UIC barcodes
public enum CompressionUtility {

    // MARK: - Decompression

    /// Decompress DEFLATE-compressed data
    /// - Parameter data: The compressed data
    /// - Returns: The decompressed data
    /// - Throws: UICBarcodeError if decompression fails
    public static func decompress(_ data: Data) throws -> Data {
        // Apple's COMPRESSION_ZLIB expects raw DEFLATE data.
        // Real-world UIC tickets use zlib-wrapped data (RFC 1950):
        //   2-byte header (e.g. 78 9c) + DEFLATE payload + 4-byte Adler32 checksum.
        // Try stripping the zlib header first, fall back to raw.
        if data.count > 6, data[data.startIndex] == 0x78 {
            let cmf = data[data.startIndex]
            let flg = data[data.startIndex + 1]
            if (UInt16(cmf) * 256 + UInt16(flg)) % 31 == 0 {
                if let result = try? decompressWithAlgorithm(Data(data.dropFirst(2)), algorithm: COMPRESSION_ZLIB) {
                    return result
                }
            }
        }

        return try decompressWithAlgorithm(data, algorithm: COMPRESSION_ZLIB)
    }

    /// Decompress raw DEFLATE data (no zlib header)
    public static func decompressRawDeflate(_ data: Data) throws -> Data {
        return try decompressWithAlgorithm(data, algorithm: COMPRESSION_LZFSE)
    }

    /// Decompress using specified algorithm
    private static func decompressWithAlgorithm(_ data: Data, algorithm: compression_algorithm) throws -> Data {
        var sourceBuffer = [UInt8](data)

        // Try progressively larger buffers
        for multiplier in [8, 16, 32] {
            var destinationBuffer = [UInt8](repeating: 0, count: data.count * multiplier)

            let decompressedSize = compression_decode_buffer(
                &destinationBuffer,
                destinationBuffer.count,
                &sourceBuffer,
                sourceBuffer.count,
                nil,
                algorithm
            )

            if decompressedSize > 0 {
                return Data(destinationBuffer.prefix(decompressedSize))
            }
        }

        throw UICBarcodeError.decompressionFailed("DEFLATE decompression failed")
    }

    /// Decompress DEFLATE data using streaming (for larger data)
    /// Note: For most UIC barcodes, the standard decompress() is sufficient.
    public static func decompressStreaming(_ data: Data, maxOutputSize: Int = 65536) throws -> Data {
        // For simplicity and safety, use the non-streaming version
        // The streaming version would be needed only for very large data
        let result = try decompress(data)
        guard result.count <= maxOutputSize else {
            throw UICBarcodeError.decompressionFailed("Decompressed data exceeds maximum size")
        }
        return result
    }

    // MARK: - Compression

    /// Compress data using DEFLATE
    /// - Parameter data: The data to compress
    /// - Returns: The compressed data
    /// - Throws: UICBarcodeError if compression fails
    public static func compress(_ data: Data) throws -> Data {
        var destinationBuffer = [UInt8](repeating: 0, count: data.count + 64)
        var sourceBuffer = [UInt8](data)

        let compressedSize = compression_encode_buffer(
            &destinationBuffer,
            destinationBuffer.count,
            &sourceBuffer,
            sourceBuffer.count,
            nil,
            COMPRESSION_ZLIB
        )

        guard compressedSize > 0 else {
            throw UICBarcodeError.compressionFailed("DEFLATE compression failed")
        }

        return Data(destinationBuffer.prefix(compressedSize))
    }
}

// MARK: - Alternative: NSData-based Decompression

extension Data {
    /// Decompress this data using zlib/DEFLATE
    public func decompressed() throws -> Data {
        return try CompressionUtility.decompress(self)
    }

    /// Compress this data using zlib/DEFLATE
    public func compressed() throws -> Data {
        return try CompressionUtility.compress(self)
    }
}
