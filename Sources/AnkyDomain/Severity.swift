public struct Severity: Equatable, Hashable, Sendable, Codable {
    public let value: Int

    public init?(_ value: Int) {
        guard (0 ... 10).contains(value) else { return nil }
        self.value = value
    }

    public init?(exactly value: Double) {
        guard let whole = Int(exactly: value) else { return nil }
        self.init(whole)
    }

    public var text: String {
        "\(value) of 10"
    }

    public static func startLevel(after saved: [Entry]) -> Severity {
        saved.last?.severity ?? Severity(0)!
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        guard let severity = Self(value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Severity outside 0 to 10")
        }
        self = severity
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
