// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

enum SwipeShade {
    static let light = UIColor(red: 232 / 255, green: 232 / 255, blue: 237 / 255, alpha: 1)
    static let dark = UIColor(red: 44 / 255, green: 44 / 255, blue: 46 / 255, alpha: 1)

    static var color: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
