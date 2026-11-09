// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain

enum RowSymbol {
    static func name(for kind: EntryKind) -> String {
        switch kind {
        case .pain: "bolt.fill"
        case .stiffness: "lock.fill"
        case .fatigue: "battery.50percent"
        }
    }

    static let dose = "pills"
}
