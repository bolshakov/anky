// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import AnkyStore
import SwiftUI
import TipKit

@main
struct AnkyApp: App {
    @State private var model: EntryLogModel
    @State private var medications: MedicationsModel

    init() {
        let folder = ShortcutsLocation.fileURL().deletingLastPathComponent()
        try? Tips.configure(Self.tipOptions(folder: folder))
        let shortcutsStore = FileShortcutsStore(fileURL: ShortcutsLocation.fileURL(), protection: .complete)
        let shortcuts = ShortcutsModel(log: ShortcutsLog(store: shortcutsStore))
        let tipStore = FileTipProgressStore(
            fileURL: folder.appending(path: "tip-progress.json"),
            protection: .complete
        )
        _model = State(initialValue: EntryLogModel(
            log: EntryLog(store: Self.entryStore()),
            shortcuts: shortcuts,
            tipProgress: TipProgressModel(store: tipStore)
        ))
        _medications = State(initialValue: MedicationsModel(store: Self.medicationStore()))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, medications: medications)
                .tint(Color("AccentColor"))
        }
    }

    private static func entryStore() -> EntryStore {
        DeferredEntryStore {
            try SwiftDataEntryStore(url: EntriesLocation.storeURL(), beforeSave: entryWriteGuard)
        }
    }

    private static var entryWriteGuard: @MainActor () throws -> Void {
        #if DEBUG
            let folder = EntriesLocation.folder()
            return { try EntryWriteSwitch.check(folder: folder) }
        #else
            return {}
        #endif
    }

    private static func medicationStore() -> MedicationStore {
        DeferredMedicationStore {
            try SwiftDataMedicationStore(url: MedicationsLocation.fileURL(), beforeSave: medicationWriteGuard)
        }
    }

    private static var medicationWriteGuard: @MainActor () throws -> Void {
        #if DEBUG
            let folder = MedicationsLocation.folder()
            return { try MedicationWriteSwitch.check(folder: folder) }
        #else
            return {}
        #endif
    }

    private static func tipOptions(folder: URL) -> [Tips.ConfigurationOption] {
        #if DEBUG
            [.displayFrequency(.immediate), .datastoreLocation(.url(folder))]
        #else
            [.displayFrequency(.immediate)]
        #endif
    }
}
