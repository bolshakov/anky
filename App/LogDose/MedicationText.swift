// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

extension TakenAs {
    var title: LocalizedStringKey {
        switch self {
        case .asNeeded: "As needed"
        case .scheduled: "Scheduled"
        }
    }
}

extension CheckInDelay {
    var title: LocalizedStringResource {
        switch self {
        case .thirtyMinutes: "30 minutes"
        case .oneHour: "1 hour"
        case .twoHours: "2 hours"
        case .threeHours: "3 hours"
        case .fourHours: "4 hours"
        }
    }
}
