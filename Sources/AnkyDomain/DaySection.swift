// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct DaySection: Identifiable, Equatable, Sendable {
    public let id: Date
    public let header: DayHeader
    public let entries: [Entry]
}
