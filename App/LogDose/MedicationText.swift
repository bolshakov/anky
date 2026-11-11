// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

extension TakenAs {
    var title: LocalizedStringResource {
        switch self {
        case .asNeeded: "As needed"
        case .scheduled: "Scheduled"
        }
    }
}

extension MedicationScheduleLine {
    static func shown(takenAs: TakenAs, schedule: MedicationSchedule?) -> String {
        text(takenAs: takenAs, schedule: schedule, locale: .current, calendar: .current, bundle: .main)
    }
}

extension Medication {
    var scheduleLine: String {
        MedicationScheduleLine.shown(takenAs: takenAs, schedule: schedule)
    }

    var spokenRowLabel: String {
        "\(listTitle), \(scheduleLine)"
    }
}

extension CheckInDelay {
    var title: LocalizedStringResource {
        rawValue < 60 ? "\(rawValue) minutes" : "\(rawValue / 60) hours"
    }
}
