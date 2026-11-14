// SPDX-License-Identifier: GPL-3.0-or-later

public struct OpenSheets: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let newEntry = OpenSheets(rawValue: 1 << 0)
    public static let logDose = OpenSheets(rawValue: 1 << 1)
    public static let basdai = OpenSheets(rawValue: 1 << 2)
    public static let editingEntry = OpenSheets(rawValue: 1 << 3)
    public static let editingDose = OpenSheets(rawValue: 1 << 4)
    public static let checkingIn = OpenSheets(rawValue: 1 << 5)
}

public enum ReminderForm: Equatable, Sendable {
    case checkIn, newEntry, logDose
}

public enum ReminderSheetStep: Equatable, Sendable {
    case openNow
    case closeSheetsFirst
    case ignore
}

/// What a tapped reminder does to the sheets on Today. SwiftUI can drop a sheet presented while another one is still on
/// its way out, so a form never opens over an open sheet. The open sheets close and the form opens once they have gone.
public enum ReminderSheetPlan {
    public static func step(for form: ReminderForm, open: OpenSheets) -> ReminderSheetStep {
        switch form {
        case .checkIn:
            return open.subtracting(.checkingIn).isEmpty ? .openNow : .closeSheetsFirst
        case .newEntry:
            if open.contains(.newEntry) {
                return .ignore
            }
            return open.isEmpty ? .openNow : .closeSheetsFirst
        case .logDose:
            return open.isEmpty ? .openNow : .closeSheetsFirst
        }
    }
}
