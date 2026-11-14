// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
    @Published fileprivate var pending: AddDestination?

    func scene(
        _: UIScene,
        willConnectTo _: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let item = connectionOptions.shortcutItem {
            pending = AddAction.destination(forID: item.type)
        }
    }

    func windowScene(
        _: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let destination = AddAction.destination(forID: shortcutItem.type)
        pending = destination
        completionHandler(destination != nil)
    }
}

private struct ForwardQuickActions: ViewModifier {
    @EnvironmentObject private var sceneDelegate: QuickActionSceneDelegate
    let taps: ReminderTapModel

    func body(content: Content) -> some View {
        content.onReceive(sceneDelegate.$pending.compactMap(\.self)) { destination in
            sceneDelegate.pending = nil
            taps.received(destination)
        }
    }
}

extension View {
    func forwardingQuickActions(to taps: ReminderTapModel) -> some View {
        modifier(ForwardQuickActions(taps: taps))
    }
}
