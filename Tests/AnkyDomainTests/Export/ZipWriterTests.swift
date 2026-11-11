// SPDX-License-Identifier: GPL-3.0-or-later
@testable import AnkyDomain
import Foundation
import Testing

struct ZipWriterTests {
    private let first = ZipFile(name: "a.txt", data: Data("hi".utf8))
    private let second = ZipFile(name: "dir/b.csv", data: Data("abc".utf8))

    @Test func eachFileHasAStoredLocalHeaderDatedTheFirstOfJanuary1980() throws {
        let zip = try ZipBytes(ZipWriter.archive([first, second]))
        zip.expectLocalHeader(at: 0, ExpectedFile(name: "a.txt", crc: 0xD893_2AAC, size: 2))
        #expect(zip.text(at: 35, count: 2) == "hi")
        zip.expectLocalHeader(at: 37, ExpectedFile(name: "dir/b.csv", crc: 0x3524_41C2, size: 3))
        #expect(zip.text(at: 76, count: 3) == "abc")
    }

    @Test func theCentralDirectoryFollowsTheFilesInTheGivenOrder() throws {
        let zip = try ZipBytes(ZipWriter.archive([first, second]))
        zip.expectCentralHeader(at: 79, ExpectedFile(name: "a.txt", crc: 0xD893_2AAC, size: 2, offset: 0))
        zip.expectCentralHeader(at: 130, ExpectedFile(name: "dir/b.csv", crc: 0x3524_41C2, size: 3, offset: 37))
    }

    @Test func theEndRecordCountsTheFilesAndPointsAtTheCentralDirectory() throws {
        let zip = try ZipBytes(ZipWriter.archive([first, second]))
        zip.expectEndRecord(at: 185, files: 2, directorySize: 106, directoryOffset: 79)
        #expect(zip.bytes.count == 207)
    }

    @Test func aZeroByteFileHasZeroSizesAndZeroCRC() throws {
        let zip = try ZipBytes(ZipWriter.archive([ZipFile(name: "empty.csv", data: Data())]))
        zip.expectLocalHeader(at: 0, ExpectedFile(name: "empty.csv", crc: 0, size: 0))
        zip.expectCentralHeader(at: 39, ExpectedFile(name: "empty.csv", crc: 0, size: 0, offset: 0))
        zip.expectEndRecord(at: 94, files: 1, directorySize: 55, directoryOffset: 39)
    }

    @Test func noFilesGiveOnlyTheEndRecord() throws {
        let zip = try ZipBytes(ZipWriter.archive([]))
        zip.expectEndRecord(at: 0, files: 0, directorySize: 0, directoryOffset: 0)
        #expect(zip.bytes.count == 22)
    }

    @Test func theSameFilesGiveTheSameBytes() throws {
        #expect(try ZipWriter.archive([first, second]) == ZipWriter.archive([first, second]))
    }

    @Test func swappedFilesAreWrittenInTheirNewOrder() throws {
        let zip = try ZipBytes(ZipWriter.archive([second, first]))
        zip.expectLocalHeader(at: 0, ExpectedFile(name: "dir/b.csv", crc: 0x3524_41C2, size: 3))
        zip.expectLocalHeader(at: 42, ExpectedFile(name: "a.txt", crc: 0xD893_2AAC, size: 2))
        zip.expectCentralHeader(at: 79, ExpectedFile(name: "dir/b.csv", crc: 0x3524_41C2, size: 3, offset: 0))
        zip.expectCentralHeader(at: 134, ExpectedFile(name: "a.txt", crc: 0xD893_2AAC, size: 2, offset: 42))
    }

    @Test func aNameThatIsNotASCIIThrows() {
        #expect(throws: ZipError.nameNotASCII) {
            try ZipWriter.archive([first, ZipFile(name: "naïve.csv", data: Data())])
        }
    }

    @Test func moreThan65535FilesThrow() {
        let files = Array(repeating: ZipFile(name: "a", data: Data()), count: 65536)
        #expect(throws: ZipError.tooManyFiles) { try ZipWriter.archive(files) }
    }

    @Test func exactly65535FilesAreWithinTheLimit() throws {
        try ZipWriter.checkLimits(Array(repeating: ZipFileSize(nameLength: 1, dataCount: 0), count: 65535))
    }

    @Test func anArchiveOfExactly4GiBMinusOneByteIsWithinTheLimit() throws {
        try ZipWriter.checkLimits([ZipFileSize(nameLength: 1, dataCount: Self.largestDataForOneFile)])
    }

    @Test func anArchiveOneByteOverTheLimitThrows() {
        #expect(throws: ZipError.tooLarge) {
            try ZipWriter.checkLimits([ZipFileSize(nameLength: 1, dataCount: Self.largestDataForOneFile + 1)])
        }
    }

    @Test func aFileOver4GiBThrows() {
        #expect(throws: ZipError.tooLarge) {
            try ZipWriter.checkLimits([ZipFileSize(nameLength: 1, dataCount: Int(UInt32.max) + 1)])
        }
    }

    @Test func smallFilesWhoseSumIsOver4GiBThrow() {
        let half = ZipFileSize(nameLength: 1, dataCount: Int(UInt32.max / 2))
        #expect(throws: ZipError.tooLarge) { try ZipWriter.checkLimits([half, half]) }
    }

    /// One file named with one byte, with its local header, central header and the end record around it.
    private static let largestDataForOneFile = Int(UInt32.max) - (30 + 1) - (46 + 1) - 22
}

private struct ExpectedFile {
    let name: String
    let crc: UInt32
    let size: UInt32
    var offset: UInt32 = 0
}

private struct ZipBytes {
    let bytes: [UInt8]

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    func u16(_ at: Int) -> UInt16 {
        UInt16(bytes[at]) | UInt16(bytes[at + 1]) << 8
    }

    func u32(_ at: Int) -> UInt32 {
        UInt32(u16(at)) | UInt32(u16(at + 2)) << 16
    }

    func text(at: Int, count: Int) -> String? {
        String(bytes: bytes[at ..< at + count], encoding: .ascii)
    }

    func expectLocalHeader(at start: Int, _ file: ExpectedFile) {
        #expect(u32(start) == 0x0403_4B50)
        #expect([u16(start + 4), u16(start + 6), u16(start + 8)] == [10, 0, 0], "version, flags, method")
        #expect([u16(start + 10), u16(start + 12)] == [0, 0x0021], "time, date")
        #expect([u32(start + 14), u32(start + 18), u32(start + 22)] == [file.crc, file.size, file.size])
        #expect([u16(start + 26), u16(start + 28)] == [UInt16(file.name.utf8.count), 0], "name and extra lengths")
        #expect(text(at: start + 30, count: file.name.utf8.count) == file.name)
    }

    func expectCentralHeader(at start: Int, _ file: ExpectedFile) {
        #expect(u32(start) == 0x0201_4B50)
        #expect([u16(start + 4), u16(start + 6), u16(start + 8), u16(start + 10)] == [0x14, 10, 0, 0])
        #expect([u16(start + 12), u16(start + 14)] == [0, 0x0021], "time, date")
        #expect([u32(start + 16), u32(start + 20), u32(start + 24)] == [file.crc, file.size, file.size])
        #expect(u16(start + 28) == UInt16(file.name.utf8.count))
        #expect([u16(start + 30), u16(start + 32), u16(start + 34), u16(start + 36)] == [0, 0, 0, 0],
                "extra and comment lengths, disk, internal attributes")
        #expect([u32(start + 38), u32(start + 42)] == [0, file.offset], "external attributes, local offset")
        #expect(text(at: start + 46, count: file.name.utf8.count) == file.name)
    }

    func expectEndRecord(at start: Int, files: UInt16, directorySize: UInt32, directoryOffset: UInt32) {
        #expect(u32(start) == 0x0605_4B50)
        #expect([u16(start + 4), u16(start + 6), u16(start + 8), u16(start + 10)] == [0, 0, files, files])
        #expect([u32(start + 12), u32(start + 16)] == [directorySize, directoryOffset])
        #expect(u16(start + 20) == 0, "comment length")
        #expect(bytes.count == start + 22)
    }
}
