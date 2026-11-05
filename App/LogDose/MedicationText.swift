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
        rawValue < 60 ? "\(rawValue) minutes" : "\(rawValue / 60) hours"
    }
}
