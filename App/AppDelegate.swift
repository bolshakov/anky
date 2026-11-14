// SPDX-License-Identifier: GPL-3.0-or-later
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.shortcutItems = AddAction.all.map { action in
            UIApplicationShortcutItem(
                type: action.id,
                localizedTitle: String(localized: action.title),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: action.symbol),
                userInfo: nil
            )
        }
        return true
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = QuickActionSceneDelegate.self
        return configuration
    }
}
