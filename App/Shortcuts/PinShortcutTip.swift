import TipKit

struct PinShortcutTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("Pin a shortcut")
    }

    var message: Text? {
        Text("Swipe a place right to pin it as a shortcut on New Entry.")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
