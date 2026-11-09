// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

extension MorePlacesValue {
    var namesText: String {
        guard !all.isEmpty else { return noneText }
        let shown = SpokenList.items(names.map(placeName), locale: .current)
        guard more > 0 else { return SpokenList.joined(shown, locale: .current) }
        return String(localized: "\(shown[0]), \(shown[1]) and \(more) more")
    }

    var countText: String {
        guard !all.isEmpty else { return noneText }
        return String(localized: "\(all.count) places")
    }

    var listText: String {
        guard !all.isEmpty else { return noneText }
        return SpokenList.joined(all.map(placeName), locale: .current)
    }

    private var noneText: String {
        String(localized: "None")
    }
}

private func placeName(_ place: PlaceID) -> String {
    String(localized: place.displayName)
}
