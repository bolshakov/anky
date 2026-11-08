// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain

enum RowSymbol {
    static func name(for kind: EntryKind) -> String {
        switch kind {
        case .pain: "bandage"
        case .stiffness: "figure.flexibility"
        case .fatigue: "battery.50percent"
        }
    }

    static let dose = "pills"
}
