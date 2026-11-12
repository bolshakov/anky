// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

/// Calls `onAttempt` when a swipe tries to close the sheet it sits in while `interactiveDismissDisabled` blocks it.
/// SwiftUI offers no callback for a blocked dismiss.
struct BasdaiDismissGuard: UIViewControllerRepresentable {
    let onAttempt: () -> Void

    func makeUIViewController(context _: Context) -> GuardController {
        GuardController(onAttempt: onAttempt)
    }

    func updateUIViewController(_ controller: GuardController, context _: Context) {
        controller.relay.onAttempt = onAttempt
    }

    final class GuardController: UIViewController {
        let relay: DismissAttemptRelay

        init(onAttempt: @escaping () -> Void) {
            relay = DismissAttemptRelay(onAttempt: onAttempt)
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            nil
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            var top: UIViewController = self
            while let parent = top.parent {
                top = parent
            }
            relay.install(on: top.presentationController)
        }
    }
}

/// Stands in as the sheet's presentation delegate and hands every call on to the delegate SwiftUI set, so SwiftUI
/// still learns when the sheet closes.
final class DismissAttemptRelay: NSObject, UIAdaptivePresentationControllerDelegate {
    var onAttempt: () -> Void
    private weak var original: UIAdaptivePresentationControllerDelegate?

    init(onAttempt: @escaping () -> Void) {
        self.onAttempt = onAttempt
    }

    func install(on controller: UIPresentationController?) {
        guard let controller, controller.delegate !== self else { return }
        original = controller.delegate
        controller.delegate = self
    }

    func presentationControllerDidAttemptToDismiss(_ controller: UIPresentationController) {
        onAttempt()
        original?.presentationControllerDidAttemptToDismiss?(controller)
    }

    override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || original?.responds(to: selector) == true
    }

    override func forwardingTarget(for _: Selector!) -> Any? {
        original
    }
}
