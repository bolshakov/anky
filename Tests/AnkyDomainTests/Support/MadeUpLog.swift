// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// Made-up entries for the scale tests. Index order is save order, and the same entries come back on every call apart
/// from their ids.
enum MadeUpLog {
    static let size = 11000

    private static let spacing: TimeInterval = 8 * 3600
    private static let kinds: [EntryKind] = [.pain, .stiffness, .fatigue]
    private static let places = ["lower", "neck", "hip_l", "si_r"].map { PlaceID(rawValue: $0) }

    /// The tail, from the end of save order, is what the tests pin. The last entry is saved late with a date 70 hours
    /// back. The two before it share a date, so the later saved one comes first. The fourth from the end repeats the
    /// group of the second from the end.
    static func entries(endingAt newest: Date) -> [Entry] {
        (0 ..< size).map { index in
            let group = group(at: index)
            return Entry(
                id: UUID(),
                kind: group.kind,
                severity: group.severity,
                date: date(at: index, endingAt: newest),
                note: nil,
                places: group.places
            )
        }
    }

    /// The same groups in the same save order, every entry dated `newest`, as a run of quick repeats would leave them.
    static func sharingOneDate(endingAt newest: Date) -> [Entry] {
        entries(endingAt: newest).map { entry in
            Entry(
                id: entry.id,
                kind: entry.kind,
                severity: entry.severity,
                date: newest,
                note: nil,
                places: entry.places
            )
        }
    }

    private struct Group {
        let kind: EntryKind
        let severity: Severity
        let places: [PlaceID]
    }

    private static func date(at index: Int, endingAt newest: Date) -> Date {
        switch index {
        case size - 1: newest.addingTimeInterval(-70 * 3600)
        case size - 3: newest.addingTimeInterval(-spacing)
        default: newest.addingTimeInterval(-Double(size - 1 - index) * spacing)
        }
    }

    private static func group(at index: Int) -> Group {
        let index = index == size - 4 ? size - 2 : index
        return Group(kind: kinds[index % 3], severity: Severity(index % 11)!, places: [places[index % 4]])
    }
}
