// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct CheckInView: View {
    let dose: Dose
    let medications: MedicationsModel
    let model: EntryLogModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var checkIn = CheckInSave()
    @State private var isShowingPlaces = false
    @State private var isShowingSaveFailure = false

    init(dose: Dose, medications: MedicationsModel, model: EntryLogModel, onSaved: @escaping () -> Void) {
        self.dose = dose
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
        _draft = State(initialValue: DoseReadings(dose, in: model.entries).checkInDraft(now: .now))
    }

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                Section {
                    KindSection(draft: $draft)
                        .nonCardBlock()
                }
                SystemSeveritySection(
                    caption: severityCaption,
                    spokenLabel: severityCaption,
                    idPrefix: "severity",
                    severity: $draft.severity,
                    footer: footnote,
                    footerID: "check-in-saved-footnote"
                )
                whereSection
                CardSection(id: "date") {
                    DateSection(date: $draft.date)
                }
                NoteSection(draft: $draft)
                saveSection
            }
            .screenSpacing()
            .accessibilityIdentifier("check-in-screen")
            .shortcutFeedback(model.shortcuts)
            .navigationDestination(isPresented: $isShowingPlaces) {
                PlacesListView(draft: $draft)
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: Spacing.rowMinimumHeight)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("check-in-cancel")
                }
            }
            .alert("Couldn't save this check-in. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
        }
        .pinLimitAlert(model.shortcuts)
        .environment(model.shortcuts)
        .environment(model.tipProgress)
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.tightGap) {
                Text(verbatim: infoTitle)
                    .font(.headline)
                Text(infoDetail)
                    .font(.subheadline)
            }
            .foregroundStyle(Color.onSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.soft, in: .card)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(infoTitle). \(infoDetail)")
            .accessibilityIdentifier("check-in-info")
            .nonCardBlock()
        }
    }

    private var saveSection: some View {
        Section {
            Button(action: saveCheckIn) {
                Text("Save")
                    .frame(maxWidth: .infinity, minHeight: Spacing.primaryButtonLabelHeight)
            }
            .primaryButton()
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .accessibilityIdentifier("save-check-in")
            .nonCardBlock()
        }
    }

    @ViewBuilder
    private var whereSection: some View {
        if draft.kind.asksWhere {
            WhereSection(draft: $draft, isShowingPlaces: $isShowingPlaces, chips: chips)
        }
    }

    private var chips: [PlaceID] {
        PlaceChips.chips(
            from: model.entries,
            pinned: model.shortcuts.pinned,
            lastChips: model.shortcuts.lastChips
        )
    }

    private func saveCheckIn() {
        do {
            let saved = try checkIn.save(
                draft,
                for: dose,
                addEntry: model.add,
                replaceDose: medications.replaceDose
            )
            if saved {
                onSaved()
            }
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }

    private var severityCaption: LocalizedStringKey {
        CheckInText.severityCaption(for: draft.kind)
    }

    private var footnote: Text {
        CheckInText.footnote(for: draft.kind, startsAtEarlierReading: readings.before != nil)
    }

    private var readings: DoseReadings {
        DoseReadings(dose, in: model.entries)
    }

    private var infoTitle: String {
        DoseRowText.title(for: dose, in: medications.medications)
    }

    private var infoDetail: String {
        CheckInText.infoTaken(takenAt: dose.takenAt, before: readings.before)
    }
}
