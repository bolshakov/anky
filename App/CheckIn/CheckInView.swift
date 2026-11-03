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
                questionSection
                SystemSeveritySection(
                    caption: severityCaption,
                    spokenLabel: severityCaption,
                    idPrefix: "severity",
                    severity: $draft.severity
                )
                Section {
                    DateSection(date: $draft.date)
                }
                if draft.kind.asksWhere {
                    CheckInWhereSection(draft: $draft, footer: whereFooter)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("PageBackground"))
            .shortcutFeedback(model.shortcuts)
            .accessibilityIdentifier("check-in-screen")
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("check-in-cancel")
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .alert("This check-in could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .pinLimitAlert(model.shortcuts)
            .environment(model.shortcuts)
            .environment(model.tipProgress)
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(infoTitle)
                    .font(.headline)
                Text(infoDetail)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color("CardBackground"), in: .card)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(infoTitle). \(infoDetail)")
            .accessibilityIdentifier("check-in-info")
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private var questionSection: some View {
        Section {
            Text(CheckInText.question(for: draft.kind))
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("check-in-question")
        }
        .listRowBackground(Color.clear)
    }

    private var saveButton: some View {
        Button {
            saveCheckIn()
        } label: {
            Text("Save check-in")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .accessibilityIdentifier("save-check-in")
        .padding()
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

    private var readings: DoseReadings {
        DoseReadings(dose, in: model.entries)
    }

    private var whereFooter: String {
        CheckInText.whereFooter(for: draft.kind, startsAtEarlierReading: readings.before != nil)
    }

    private var infoTitle: String {
        CheckInText.infoTitle(title: DoseRowText.title(for: dose, in: medications.medications))
    }

    private var infoDetail: String {
        let time = ClockText.text(for: dose.takenAt, calendar: .current, locale: .current)
        let taken = CheckInText.infoTaken(time: time, takenAt: dose.takenAt, now: .now)
        guard let before = readings.before else { return taken }
        return "\(taken) \(CheckInText.infoPain(before))"
    }
}
