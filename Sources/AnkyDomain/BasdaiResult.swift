// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One saved BASDAI questionnaire. It holds the six answers, Q1 to Q6, and no score, since the score is computed from
/// the answers each time.
public struct BasdaiResult: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var date: Date
    public var createdAt: Date
    public var updatedAt: Date
    public var answers: [Int]

    /// Fails unless there are exactly six answers, each from 0 to 10.
    public init?(id: UUID, date: Date, createdAt: Date, updatedAt: Date, answers: [Int]) {
        guard answers.count == 6, answers.allSatisfy((0 ... 10).contains) else { return nil }
        self.id = id
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.answers = answers
    }
}
