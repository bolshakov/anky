public struct Severity: Equatable, Sendable {
    public let value: Int

    public init?(_ value: Int) {
        guard (0 ... 10).contains(value) else { return nil }
        self.value = value
    }
}
