// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

extension MorePlacesValue {
    var namesText: String {
        guard !all.isEmpty else { return noneText }
        let shown = names.map(placeName)
        guard more > 0 else { return shown.joined(separator: ", ") }
        return String(localized: "\(shown[0]), \(shown[1]) and \(more) more")
    }

    var countText: String {
        guard !all.isEmpty else { return noneText }
        return String(localized: "\(all.count) places")
    }

    var listText: String {
        guard !all.isEmpty else { return noneText }
        return all.map(placeName).joined(separator: ", ")
    }

    private var noneText: String {
        String(localized: "None")
    }
}

private func placeName(_ place: PlaceID) -> String {
    String(localized: place.displayName)
}
