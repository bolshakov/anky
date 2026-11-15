// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import notify
    import UIKit

    /// Debug builds only, for the walks: a Darwin notification turns the screen the way a person turning the phone
    /// does. `xcrun simctl spawn <udid> notifyutil -p <name>` posts it inside that one simulator.
    enum DebugOrientation {
        static let landscapeName = "anky.debug.orientation.landscape"
        static let portraitName = "anky.debug.orientation.portrait"

        @MainActor static func listen() {
            register(name: landscapeName, orientations: .landscape)
            register(name: portraitName, orientations: .portrait)
        }

        @MainActor private static func register(name: String, orientations: UIInterfaceOrientationMask) {
            var token: Int32 = 0
            _ = notify_register_dispatch(name, &token, .main) { _ in
                MainActor.assumeIsolated { turn(to: orientations) }
            }
        }

        @MainActor private static func turn(to orientations: UIInterfaceOrientationMask) {
            let scenes = UIApplication.shared.connectedScenes
            guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                return
            }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations))
        }
    }
#endif
