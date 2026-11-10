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

extension Medication {
    var spokenRowLabel: String {
        "\(listTitle), \(String(localized: takenAs.title))"
    }
}

extension CheckInDelay {
    var title: LocalizedStringResource {
        rawValue < 60 ? "\(rawValue) minutes" : "\(rawValue / 60) hours"
    }
}
