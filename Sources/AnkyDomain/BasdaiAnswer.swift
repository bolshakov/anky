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
}
