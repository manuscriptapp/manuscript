import Foundation
import Compression

/// Builds ZIP archives for DOCX and EPUB export
/// Implements the ZIP file format specification (PKZIP)
class ZipArchiveBuilder {
    private var entries: [(path: String, data: Data, compress: Bool)] = []

    // MARK: - Adding Files

    func addFile(path: String, content: String, compress: Bool = true) throws {
        guard let data = content.data(using: .utf8) else {
            throw ZipError.encodingFailed
        }
        entries.append((path: path, data: data, compress: compress))
    }

    func addFile(path: String, data: Data, compress: Bool = true) {
        entries.append((path: path, data: data, compress: compress))
    }

    // MARK: - Finalization

    func finalize() throws -> Data {
        var zipData = Data()
        var centralDirectory = Data()
        var localHeaderOffsets: [UInt32] = []

        // Write local file headers and data
        for entry in entries {
            localHeaderOffsets.append(UInt32(zipData.count))

            let (localHeader, compressedData) = try buildLocalFileEntry(
                path: entry.path,
                data: entry.data,
                compress: entry.compress
            )

            zipData.append(localHeader)
            zipData.append(compressedData)

            // Build central directory entry
            let centralEntry = buildCentralDirectoryEntry(
                path: entry.path,
                uncompressedSize: UInt32(entry.data.count),
                compressedSize: UInt32(compressedData.count),
                crc32: entry.data.crc32,
                localHeaderOffset: localHeaderOffsets.last!,
                compress: entry.compress
            )
            centralDirectory.append(centralEntry)
        }

        let centralDirectoryOffset = UInt32(zipData.count)
        zipData.append(centralDirectory)

        // Write end of central directory
        let endRecord = buildEndOfCentralDirectory(
            entryCount: UInt16(entries.count),
            centralDirectorySize: UInt32(centralDirectory.count),
            centralDirectoryOffset: centralDirectoryOffset
        )
        zipData.append(endRecord)

        return zipData
    }

    // MARK: - Local File Entry

    private func buildLocalFileEntry(
        path: String,
        data: Data,
        compress: Bool
    ) throws -> (header: Data, data: Data) {
        let pathData = path.data(using: .utf8) ?? Data()
        let crc32 = data.crc32

        let compressedData: Data
        let compressionMethod: UInt16

        if compress && data.count > 0 {
            if let deflated = data.deflate() {
                compressedData = deflated
                compressionMethod = 8 // Deflate
            } else {
                compressedData = data
                compressionMethod = 0 // Stored
            }
        } else {
            compressedData = data
            compressionMethod = 0 // Stored
        }

        var header = Data()

        // Local file header signature
        header.appendUInt32(0x04034b50)

        // Version needed to extract
        header.appendUInt16(compressionMethod == 8 ? 20 : 10)

        // General purpose bit flag
        header.appendUInt16(0)

        // Compression method
        header.appendUInt16(compressionMethod)

        // Modification time and date (DOS format)
        let (dosTime, dosDate) = currentDosDateTime()
        header.appendUInt16(dosTime)
        header.appendUInt16(dosDate)

        // CRC-32
        header.appendUInt32(crc32)

        // Compressed size
        header.appendUInt32(UInt32(compressedData.count))

        // Uncompressed size
        header.appendUInt32(UInt32(data.count))

        // File name length
        header.appendUInt16(UInt16(pathData.count))

        // Extra field length
        header.appendUInt16(0)

        // File name
        header.append(pathData)

        return (header, compressedData)
    }

    // MARK: - Central Directory Entry

    private func buildCentralDirectoryEntry(
        path: String,
        uncompressedSize: UInt32,
        compressedSize: UInt32,
        crc32: UInt32,
        localHeaderOffset: UInt32,
        compress: Bool
    ) -> Data {
        let pathData = path.data(using: .utf8) ?? Data()
        let compressionMethod: UInt16 = (compress && uncompressedSize > 0 && compressedSize < uncompressedSize) ? 8 : 0

        var entry = Data()

        // Central file header signature
        entry.appendUInt32(0x02014b50)

        // Version made by
        entry.appendUInt16(20)

        // Version needed to extract
        entry.appendUInt16(compressionMethod == 8 ? 20 : 10)

        // General purpose bit flag
        entry.appendUInt16(0)

        // Compression method
        entry.appendUInt16(compressionMethod)

        // Modification time and date
        let (dosTime, dosDate) = currentDosDateTime()
        entry.appendUInt16(dosTime)
        entry.appendUInt16(dosDate)

        // CRC-32
        entry.appendUInt32(crc32)

        // Compressed size
        entry.appendUInt32(compressedSize)

        // Uncompressed size
        entry.appendUInt32(uncompressedSize)

        // File name length
        entry.appendUInt16(UInt16(pathData.count))

        // Extra field length
        entry.appendUInt16(0)

        // File comment length
        entry.appendUInt16(0)

        // Disk number start
        entry.appendUInt16(0)

        // Internal file attributes
        entry.appendUInt16(0)

        // External file attributes
        entry.appendUInt32(0)

        // Relative offset of local header
        entry.appendUInt32(localHeaderOffset)

        // File name
        entry.append(pathData)

        return entry
    }

    // MARK: - End of Central Directory

    private func buildEndOfCentralDirectory(
        entryCount: UInt16,
        centralDirectorySize: UInt32,
        centralDirectoryOffset: UInt32
    ) -> Data {
        var record = Data()

        // End of central directory signature
        record.appendUInt32(0x06054b50)

        // Number of this disk
        record.appendUInt16(0)

        // Disk where central directory starts
        record.appendUInt16(0)

        // Number of central directory records on this disk
        record.appendUInt16(entryCount)

        // Total number of central directory records
        record.appendUInt16(entryCount)

        // Size of central directory
        record.appendUInt32(centralDirectorySize)

        // Offset of start of central directory
        record.appendUInt32(centralDirectoryOffset)

        // Comment length
        record.appendUInt16(0)

        return record
    }

    // MARK: - Helpers

    private func currentDosDateTime() -> (time: UInt16, date: UInt16) {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)

        let year = max(0, (components.year ?? 1980) - 1980)
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = (components.second ?? 0) / 2

        let dosDate = UInt16((year << 9) | (month << 5) | day)
        let dosTime = UInt16((hour << 11) | (minute << 5) | second)

        return (dosTime, dosDate)
    }
}

// MARK: - Zip Error

enum ZipError: LocalizedError {
    case encodingFailed
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode file content"
        case .compressionFailed:
            return "Failed to compress file data"
        }
    }
}

// MARK: - Data Extensions

extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 2))
    }

    mutating func appendUInt32(_ value: UInt32) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 4))
    }

    /// Calculates CRC-32 checksum
    var crc32: UInt32 {
        var crc: UInt32 = 0xFFFFFFFF

        for byte in self {
            var lookup = (crc ^ UInt32(byte)) & 0xFF
            for _ in 0..<8 {
                lookup = (lookup & 1) != 0 ? (lookup >> 1) ^ 0xEDB88320 : lookup >> 1
            }
            crc = (crc >> 8) ^ lookup
        }

        return ~crc
    }

    /// Compresses data using DEFLATE algorithm
    func deflate() -> Data? {
        guard !isEmpty else { return nil }

        // Use a buffer that's definitely large enough
        let destinationBufferSize = count + 512
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer { destinationBuffer.deallocate() }

        let compressedSize = self.withUnsafeBytes { sourceBuffer -> Int in
            guard let sourcePtr = sourceBuffer.baseAddress else { return 0 }

            return compression_encode_buffer(
                destinationBuffer,
                destinationBufferSize,
                sourcePtr.assumingMemoryBound(to: UInt8.self),
                count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else { return nil }

        // ZLIB format includes 2-byte header and 4-byte trailer (Adler-32)
        // DEFLATE raw is just the compressed data without header/trailer
        // compression_encode_buffer with COMPRESSION_ZLIB gives raw deflate
        return Data(bytes: destinationBuffer, count: compressedSize)
    }
}
