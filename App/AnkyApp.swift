// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI
import TipKit

@main
struct AnkyApp: App {
    @State private var model: EntryLogModel

    init() {
        let folder = ShortcutsLocation.fileURL().deletingLastPathComponent()
        try? Tips.configure(Self.tipOptions(folder: folder))
        let store = FileEntryStore(fileURL: EntriesLocation.fileURL(), protection: .complete)
        let shortcutsStore = FileShortcutsStore(fileURL: ShortcutsLocation.fileURL(), protection: .complete)
        let shortcuts = ShortcutsModel(log: ShortcutsLog(store: shortcutsStore))
        let tipStore = FileTipProgressStore(
            fileURL: folder.appending(path: "tip-progress.json"),
            protection: .complete
        )
        _model = State(initialValue: EntryLogModel(
            log: EntryLog(store: store),
            shortcuts: shortcuts,
            tipProgress: TipProgressModel(store: tipStore)
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .tint(Color("AccentColor"))
        }
    }

    private static func tipOptions(folder: URL) -> [Tips.ConfigurationOption] {
        #if DEBUG
            [.displayFrequency(.immediate), .datastoreLocation(.url(folder))]
        #else
            [.displayFrequency(.immediate)]
        #endif
    }
}
