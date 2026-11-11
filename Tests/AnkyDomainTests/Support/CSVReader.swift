// SPDX-License-Identifier: GPL-3.0-or-later
/// Reads RFC 4180 text back into records of plain strings, so a test can check what a spreadsheet would see.
/// It reads scalars, not characters, because Swift counts "\r\n" as one character.
enum CSVReader {
    static func records(_ text: String) -> [[String]] {
        var reading = Reading()
        for scalar in text.unicodeScalars {
            reading.take(scalar)
        }
        return reading.records
    }
}

private struct Reading {
    var records: [[String]] = []
    private var fields: [String] = []
    private var field = String.UnicodeScalarView()
    private var isQuoted = false
    private var justClosedQuote = false

    mutating func take(_ scalar: Unicode.Scalar) {
        if isQuoted {
            takeQuoted(scalar)
        } else {
            takeBare(scalar)
        }
    }

    private mutating func takeQuoted(_ scalar: Unicode.Scalar) {
        if scalar == "\"" {
            isQuoted = false
            justClosedQuote = true
        } else {
            field.append(scalar)
        }
    }

    private mutating func takeBare(_ scalar: Unicode.Scalar) {
        let reopens = justClosedQuote && scalar == "\""
        justClosedQuote = false
        switch scalar {
        case "\"":
            if reopens {
                field.append(scalar)
            }
            isQuoted = true
        case ",":
            endField()
        case "\n":
            endField()
            records.append(fields)
            fields = []
        default:
            field.append(scalar)
        }
    }

    private mutating func endField() {
        fields.append(String(field))
        field = String.UnicodeScalarView()
    }
}
