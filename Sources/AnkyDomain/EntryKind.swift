// SPDX-License-Identifier: GPL-3.0-or-later
public enum EntryKind: String, CaseIterable, Codable, Sendable {
    case pain
    case stiffness
    case fatigue

    public var asksWhere: Bool {
        self != .fatigue
    }
}
