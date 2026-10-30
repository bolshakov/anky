import AnkyDomain
import SwiftUI

@main
struct AnkyApp: App {
    @State private var model: EntryLogModel

    init() {
        let store = FileEntryStore(fileURL: EntriesLocation.fileURL(), protection: .complete)
        let shortcutsStore = FileShortcutsStore(fileURL: ShortcutsLocation.fileURL(), protection: .complete)
        let shortcuts = ShortcutsModel(log: ShortcutsLog(store: shortcutsStore))
        _model = State(initialValue: EntryLogModel(log: EntryLog(store: store), shortcuts: shortcuts))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .tint(Color("AccentColor"))
        }
    }
}
