// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

@MainActor @Observable final class BasdaiModel {
    private var log: BasdaiLog

    init(log: BasdaiLog) {
        self.log = log
    }

    var results: [BasdaiResult] {
        log.results
    }

    func add(_ r: BasdaiResult) throws {
        try log.add(r)
    }

    func remove(id: UUID) throws {
        try log.remove(id: id)
    }

    func removeAll() throws {
        try log.removeAll()
    }
}
