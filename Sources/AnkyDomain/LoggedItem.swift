// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One line of a day's log, an entry or a dose, so both kinds are listed in one order.
public enum LoggedItem: Identifiable, Equatable, Sendable {
    case entry(Entry)
    case dose(Dose)

    public var id: UUID {
        switch self {
        case let .entry(entry): entry.id
        case let .dose(dose): dose.id
        }
    }

    public var date: Date {
        switch self {
        case let .entry(entry): entry.date
        case let .dose(dose): dose.takenAt
        }
    }

    var isDose: Bool {
        if case .dose = self {
            true
        } else {
            false
        }
    }
}
