import AnkyDomain
import Observation

@MainActor @Observable final class TipProgressModel {
    @ObservationIgnored private let store: FileTipProgressStore
    private var progress: TipProgress

    init(store: FileTipProgressStore) {
        self.store = store
        progress = store.load()
        PinShortcutTip.isReady = progress.isReady
    }

    func recordVisit() {
        progress.recordVisit()
        save()
    }

    func recordPick(_ place: PlaceID) {
        progress.recordPick(place)
        save()
    }

    private func save() {
        try? store.save(progress)
        PinShortcutTip.isReady = progress.isReady
    }
}
