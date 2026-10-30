import AnkyDomain
import SwiftUI

@main
struct AnkyApp: App {
    @State private var model: EntryLogModel

    init() {
        let store = FileEntryStore(fileURL: EntriesLocation.fileURL(), protection: .complete)
        _model = State(initialValue: EntryLogModel(log: EntryLog(store: store)))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .tint(Color("AccentColor"))
        }
    }
}
