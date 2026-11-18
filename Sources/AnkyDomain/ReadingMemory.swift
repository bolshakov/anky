// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ReadingMemory: String, Sendable {
    case none, entry
}

public enum ReadingStart: Equatable, Sendable {
    case none, automatic
}

public extension ReadingStart {
    /// A remembered choice wins; without one only a Scheduled medication starts with no reading.
    static func forMedication(_ medication: Medication?) -> ReadingStart {
        switch medication?.readingMemory {
        case .none?: .none
        case .entry?: .automatic
        case nil: medication?.takenAs == .scheduled ? .none : .automatic
        }
    }
}

public extension ReadingMemory {
    /// nil leaves the stored memory as it is.
    static func toRemember(noReading: Bool, resolved: Entry?) -> ReadingMemory? {
        if noReading {
            return ReadingMemory.none
        }
        return resolved == nil ? nil : .entry
    }
}
