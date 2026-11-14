// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct ReminderSheetPlanTests {
    private static let forms: [ReminderForm] = [.checkIn, .newEntry, .logDose]

    private static let sheets: [OpenSheets] = [.newEntry, .logDose, .basdai, .editingEntry, .editingDose, .checkingIn]

    @Test(arguments: forms)
    func aFormOpensAtOnceWhenNoSheetIsOpen(form: ReminderForm) {
        #expect(ReminderSheetPlan.step(for: form, open: []) == .openNow)
    }

    @Test(arguments: forms)
    func theBasdaiSheetClosesBeforeAnyReminderFormOpens(form: ReminderForm) {
        #expect(ReminderSheetPlan.step(for: form, open: .basdai) == .closeSheetsFirst)
    }

    @Test func aCheckInReminderClosesNewEntryLogDoseAndTheEditSheetsFirst() {
        for sheet in Self.sheets where sheet != .checkingIn {
            #expect(ReminderSheetPlan.step(for: .checkIn, open: sheet) == .closeSheetsFirst, "\(sheet)")
        }
    }

    @Test func aCheckInReminderReplacesAnOpenCheckInInPlace() {
        #expect(ReminderSheetPlan.step(for: .checkIn, open: .checkingIn) == .openNow)
    }

    @Test func aNewEntryReminderIsIgnoredWhileNewEntryIsOpen() {
        #expect(ReminderSheetPlan.step(for: .newEntry, open: .newEntry) == .ignore)
    }

    @Test func aNewEntryReminderClosesEveryOtherSheetFirst() {
        for sheet in Self.sheets where sheet != .newEntry {
            #expect(ReminderSheetPlan.step(for: .newEntry, open: sheet) == .closeSheetsFirst, "\(sheet)")
        }
    }

    @Test func aLogDoseReminderClosesEveryOpenSheetFirst() {
        for sheet in Self.sheets {
            #expect(ReminderSheetPlan.step(for: .logDose, open: sheet) == .closeSheetsFirst, "\(sheet)")
        }
    }
}
