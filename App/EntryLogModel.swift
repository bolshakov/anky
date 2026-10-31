import AnkyDomain
import Foundation
import Observation

@MainActor @Observable final class EntryLogModel {
    private var log: EntryLog
    let shortcuts: ShortcutsModel
    let tipProgress: TipProgressModel

    init(log: EntryLog, shortcuts: ShortcutsModel, tipProgress: TipProgressModel) {
        self.log = log
        self.shortcuts = shortcuts
        self.tipProgress = tipProgress
    }

    var entries: [Entry] {
        log.entries
    }

    func add(_ entry: Entry) throws {
        try log.add(entry)
    }

    func replace(_ entry: Entry) throws {
        try log.replace(entry)
    }

    func remove(id: UUID) throws {
        try log.remove(id: id)
    }
}
