public enum EntryKind: String, CaseIterable, Codable, Sendable {
    case pain
    case stiffness
    case fatigue

    public var title: String {
        switch self {
        case .pain: "Pain"
        case .stiffness: "Stiffness"
        case .fatigue: "Fatigue"
        }
    }
}
