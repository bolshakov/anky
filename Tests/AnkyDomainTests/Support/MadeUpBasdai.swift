// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A synthetic result, never a real person's answers.
func madeUpBasdai(
    date: Date = Date(timeIntervalSince1970: 1_800_000_000),
    createdAt: Date? = nil,
    answers: [Int] = [4, 5, 6, 7, 3, 8]
) -> BasdaiResult {
    guard var result = BasdaiResult(id: UUID(), date: date, answers: answers) else {
        preconditionFailure("A made-up result needs six answers from 0 to 10.")
    }
    result.createdAt = createdAt ?? date
    result.updatedAt = result.createdAt
    return result
}
