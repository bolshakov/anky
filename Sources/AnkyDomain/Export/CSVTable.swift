// SPDX-License-Identifier: GPL-3.0-or-later
public enum CSVCell: Equatable, Sendable {
    case text(String)
    case number(Int)
    case empty

    var written: String {
        switch self {
        case let .text(value): "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        case let .number(value): String(value)
        case .empty: ""
        }
    }
}

/// RFC 4180 text. Every text cell is quoted, so a comma, a quote or a line break in it never splits the cell.
public struct CSVTable: Equatable, Sendable {
    public let header: [String]
    public let rows: [[CSVCell]]

    public init(header: [String], rows: [[CSVCell]]) {
        self.header = header
        self.rows = rows
    }

    public var text: String {
        let lines = [header.joined(separator: ",")] + rows.map { $0.map(\.written).joined(separator: ",") }
        return lines.map { $0 + "\n" }.joined()
    }
}
