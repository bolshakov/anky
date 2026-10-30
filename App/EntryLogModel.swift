import AnkyDomain
import Foundation
import Observation

@MainActor @Observable final class EntryLogModel {
    private var log: EntryLog

    init(log: EntryLog) {
        self.log = log
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
