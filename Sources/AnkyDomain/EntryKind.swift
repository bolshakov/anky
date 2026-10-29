public enum EntryKind: String, CaseIterable, Codable, Sendable {
    case pain
    case stiffness
    case fatigue

    public var asksWhere: Bool {
        self != .fatigue
    }
}
