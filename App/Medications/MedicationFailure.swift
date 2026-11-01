// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A medication write that did not happen. The screen keeps everything as the person left it and shows one alert.
enum MedicationFailure {
    case save, archive, restore

    var message: LocalizedStringKey {
        switch self {
        case .save: "This medication could not be saved."
        case .archive: "This medication could not be archived."
        case .restore: "This medication could not be restored."
        }
    }
}

extension View {
    func medicationFailureAlert(_ failure: Binding<MedicationFailure?>) -> some View {
        alert(
            failure.wrappedValue?.message ?? "",
            isPresented: Binding(
                get: { failure.wrappedValue != nil },
                set: {
                    if !$0 {
                        failure.wrappedValue = nil
                    }
                }
            )
        ) {
            Button("OK") {}
        }
    }
}
