// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ZipFile: Equatable, Sendable {
    public let name: String
    public let data: Data

    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
}

public enum ZipError: Error, Equatable, Sendable {
    case tooLarge, tooManyFiles, nameNotASCII
}

struct ZipFileSize {
    let nameLength: Int
    let dataCount: Int
}

/// Writes stored zips whose bytes depend only on the files given: every date is 1980-01-01 00:00 and nothing else
/// about the device or the moment is recorded, so the same files always give the same archive.
public enum ZipWriter {
    private static let localHeaderLength = 30
    private static let centralHeaderLength = 46
    private static let endRecordLength = 22
    private static let versionMadeBy: UInt16 = 0x0014
    private static let versionNeeded: UInt16 = 10
    fileprivate static let dosDate: UInt16 = 0x0021

    public static func archive(_ files: [ZipFile]) throws(ZipError) -> Data {
        for file in files where !file.name.utf8.allSatisfy({ $0 < 0x80 }) {
            throw .nameNotASCII
        }
        try checkLimits(files.map { ZipFileSize(nameLength: $0.name.utf8.count, dataCount: $0.data.count) })
        var archive = Data()
        var directory = Data()
        for file in files {
            let record = Record(file: file, offset: UInt32(archive.count))
            archive.append(localHeader(record))
            archive.append(file.data)
            directory.append(centralHeader(record))
        }
        let directoryOffset = UInt32(archive.count)
        archive.append(directory)
        archive.append(endRecord(files: UInt16(files.count), directorySize: UInt32(directory.count),
                                 directoryOffset: directoryOffset))
        return archive
    }

    static func checkLimits(_ sizes: [ZipFileSize]) throws(ZipError) {
        guard sizes.count <= Int(UInt16.max) else { throw .tooManyFiles }
        var total = endRecordLength
        for size in sizes {
            total += localHeaderLength + centralHeaderLength + 2 * size.nameLength + size.dataCount
            guard total <= Int(UInt32.max) else { throw .tooLarge }
        }
    }

    fileprivate struct Record {
        let name: Data
        let crc: UInt32
        let size: UInt32
        let offset: UInt32

        init(file: ZipFile, offset: UInt32) {
            name = Data(file.name.utf8)
            crc = CRC32.checksum(file.data)
            size = UInt32(file.data.count)
            self.offset = offset
        }
    }

    private static func localHeader(_ record: Record) -> Data {
        var header = Data()
        header.appendLittleEndian(UInt32(0x0403_4B50))
        header.appendLittleEndian(versionNeeded)
        header.appendFileFields(record)
        header.append(record.name)
        return header
    }

    private static func centralHeader(_ record: Record) -> Data {
        var header = Data()
        header.appendLittleEndian(UInt32(0x0201_4B50))
        header.appendLittleEndian(versionMadeBy)
        header.appendLittleEndian(versionNeeded)
        header.appendFileFields(record)
        header.appendLittleEndian(UInt16(0))
        header.appendLittleEndian(UInt16(0))
        header.appendLittleEndian(UInt16(0))
        header.appendLittleEndian(UInt32(0))
        header.appendLittleEndian(record.offset)
        header.append(record.name)
        return header
    }

    private static func endRecord(files: UInt16, directorySize: UInt32, directoryOffset: UInt32) -> Data {
        var record = Data()
        record.appendLittleEndian(UInt32(0x0605_4B50))
        record.appendLittleEndian(UInt16(0))
        record.appendLittleEndian(UInt16(0))
        record.appendLittleEndian(files)
        record.appendLittleEndian(files)
        record.appendLittleEndian(directorySize)
        record.appendLittleEndian(directoryOffset)
        record.appendLittleEndian(UInt16(0))
        return record
    }
}

private extension Data {
    mutating func appendLittleEndian(_ value: some FixedWidthInteger) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }

    /// The fields from flags to the extra field length, which the local and central headers share.
    mutating func appendFileFields(_ record: ZipWriter.Record) {
        appendLittleEndian(UInt16(0))
        appendLittleEndian(UInt16(0))
        appendLittleEndian(UInt16(0))
        appendLittleEndian(ZipWriter.dosDate)
        appendLittleEndian(record.crc)
        appendLittleEndian(record.size)
        appendLittleEndian(record.size)
        appendLittleEndian(UInt16(record.name.count))
        appendLittleEndian(UInt16(0))
    }
}
