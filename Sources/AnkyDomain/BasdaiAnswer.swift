// SPDX-License-Identifier: GPL-3.0-or-later
/// One BASDAI question's answer. Unanswered is its own state, not a 0, and an adjust from it counts it as 0.
public enum BasdaiAnswer: Equatable, Sendable {
    case unanswered
    case answered(Int)

    public var value: Int? {
        switch self {
        case .unanswered: nil
        case let .answered(value): value
        }
    }

    public func incremented() -> BasdaiAnswer {
        .answered(min((value ?? 0) + 1, 10))
    }

    public func decremented() -> BasdaiAnswer {
        .answered(max((value ?? 0) - 1, 0))
    }

    /// A touch on the slider answers at the value it shows, so touching the thumb at 0 records a real 0.
    public func touched() -> BasdaiAnswer {
        .answered(value ?? 0)
    }

    public func slid(to value: Int) -> BasdaiAnswer {
        .answered(value)
    }
}

public extension [BasdaiAnswer] {
    var isComplete: Bool {
        allSatisfy { $0.value != nil }
    }

    var isAnyAnswered: Bool {
        contains { $0.value != nil }
    }

    var completeValues: [Int]? {
        let values = compactMap(\.value)
        return values.count == count ? values : nil
    }
}
