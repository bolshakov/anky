import AnkyDomain
import Foundation

extension EntryKind {
    var displayName: LocalizedStringResource {
        switch self {
        case .pain: "Pain"
        case .stiffness: "Stiffness"
        case .fatigue: "Fatigue"
        }
    }
}

extension Severity {
    var spokenValue: LocalizedStringResource {
        "\(value) of \(10)"
    }
}
