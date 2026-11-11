// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import AnkyStore
import SwiftUI
import TipKit
import UserNotifications

@main
struct AnkyApp: App {
    @State private var model: EntryLogModel
    @State private var medications: MedicationsModel
    @State private var reminderTaps: ReminderTapModel
    private let reminderTapDelegate: ReminderTapDelegate

    init() {
        let folder = ShortcutsLocation.fileURL().deletingLastPathComponent()
        try? Tips.configure(Self.tipOptions(folder: folder))
        let shortcutsStore = FileShortcutsStore(fileURL: ShortcutsLocation.fileURL(), protection: .complete)
        let shortcuts = ShortcutsModel(log: ShortcutsLog(store: shortcutsStore))
        let tipStore = FileTipProgressStore(
            fileURL: folder.appending(path: "tip-progress.json"),
            protection: .complete
        )
        let model = EntryLogModel(
            log: EntryLog(store: Self.entryStore()),
            shortcuts: shortcuts,
            tipProgress: TipProgressModel(store: tipStore)
        )
        let medications = MedicationsModel(store: Self.medicationStore())
        #if DEBUG
            DebugSeed.plant(entries: model, medications: medications)
        #endif
        _model = State(initialValue: model)
        _medications = State(initialValue: medications)
        let taps = ReminderTapModel()
        _reminderTaps = State(initialValue: taps)
        reminderTapDelegate = ReminderTapDelegate(taps: taps)
        UNUserNotificationCenter.current().delegate = reminderTapDelegate
        #if DEBUG
            ReminderTapSwitch.listen(taps: taps, folder: EntriesLocation.folder())
            PendingDosesSwitch.listen(folder: EntriesLocation.folder())
            DebugDoseSeed.seed(into: medications, folder: MedicationsLocation.folder())
        #endif
        Self.colourSelectedSegments()
    }

    private static func colourSelectedSegments() {
        let segments = UISegmentedControl.appearance()
        segments.selectedSegmentTintColor = UIColor(named: "AccentColor")
        segments.setTitleTextAttributes([.foregroundColor: UIColor(named: "OnAccent") as Any], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            content.tint(Color("AccentColor"))
        }
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
            if DesignGallerySwitch.isOn {
                NavigationStack { DesignGalleryView() }
            } else {
                root
            }
        #else
            root
        #endif
    }

    private var root: some View {
        RootView(model: model, medications: medications, reminderTaps: reminderTaps)
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
