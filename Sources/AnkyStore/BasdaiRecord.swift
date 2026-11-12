// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

/// Holds the six answers and no score, since the score is worked out from the answers each time.
@Model final class BasdaiRecord {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    var q1: Int
    var q2: Int
    var q3: Int
    var q4: Int
    var q5: Int
    var q6: Int

    init(_ result: BasdaiResult) throws {
        guard result.answers.count == 6, result.answers.allSatisfy((0 ... 10).contains) else {
            throw BasdaiStoreError.notSaved
        }
        id = result.id
        createdAt = result.createdAt
        updatedAt = result.updatedAt
        date = result.date
        q1 = result.answers[0]
        q2 = result.answers[1]
        q3 = result.answers[2]
        q4 = result.answers[3]
        q5 = result.answers[4]
        q6 = result.answers[5]
    }

    func result() throws -> BasdaiResult {
        guard var result = BasdaiResult(id: id, date: date, answers: [q1, q2, q3, q4, q5, q6]) else {
            throw BasdaiStoreError.unreadable
        }
        result.createdAt = createdAt
        result.updatedAt = updatedAt
        return result
    }
}
