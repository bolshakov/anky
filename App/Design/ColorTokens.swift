// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// The only place under `App/Design` that names an asset or a UIKit colour. Write each token with the `Color.` prefix,
/// since SwiftUI has its own `.tint`, `.separator` and `.fill` that mean something else.
extension Color {
    static var surface: Color {
        Color("PageBackground")
    }

    static var card: Color {
        Color("CardBackground")
    }

    static var ink: Color {
        Color(.label)
    }

    static var ink2: Color {
        Color(.secondaryLabel)
    }

    static var separator: Color {
        Color(.separator)
    }

    static var tint: Color {
        Color("AccentColor")
    }

    static var onTint: Color {
        Color("OnAccent")
    }

    static var soft: Color {
        Color("SoftAccent")
    }

    static var onSoft: Color {
        Color("OnSoftAccent")
    }

    static var fill: Color {
        Color(.systemFill)
    }

    static var track: Color {
        Color(.systemFill)
    }

    /// A `Color` cannot hold a material, so the glass token is the system's own glass.
    static var glass: Glass {
        .regular
    }
}
