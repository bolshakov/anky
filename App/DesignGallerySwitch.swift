// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only, for the walks: while the launch environment holds `ANKY_DESIGN_GALLERY=1`, the app shows the
    /// pieces gallery in place of its tabs.
    enum DesignGallerySwitch {
        static var isOn: Bool {
            ProcessInfo.processInfo.environment["ANKY_DESIGN_GALLERY"] == "1"
        }
    }
#endif
