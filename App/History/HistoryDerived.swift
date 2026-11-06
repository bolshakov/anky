// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

struct HistoryInputs: Equatable {
    let entries: [Entry]
    let doses: [Dose]
    let medications: [Medication]
    let now: Date
}

struct HistoryDerived {
    let waiting: Set<UUID>
    let nextCheckInChange: Date?
    let entriesByID: EntriesByID

    init(_ inputs: HistoryInputs) {
        waiting = Set(CheckInDue.waiting(
            doses: inputs.doses,
            medications: inputs.medications,
            entries: inputs.entries,
            now: inputs.now
        ).map(\.id))
        nextCheckInChange = CheckInDue.nextChange(
            doses: inputs.doses,
            medications: inputs.medications,
            entries: inputs.entries,
            after: inputs.now
        )
        entriesByID = EntriesByID(inputs.entries)
    }
}
