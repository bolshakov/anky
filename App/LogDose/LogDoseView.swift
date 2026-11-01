// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

enum DoseMode {
    case new
}

struct LogDoseView: View {
    let medications: MedicationsModel
    let onSaved: () -> Void
    private let prefill: Entry?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var selectionTicks = 0
    @State private var saveTicks = 0
    @State private var isShowingNewMedication = false
    // Made once per opening, so a second tap on "Save dose" logs the same dose again.
    @State private var doseID = UUID()
    @State private var takenAt = Date.now
    @State private var painBefore: Severity
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false

    init(medications: MedicationsModel, entries: [Entry], mode: DoseMode = .new, onSaved: @escaping () -> Void) {
        self.medications = medications
        self.onSaved = onSaved
        let prefill: Entry? = switch mode {
        case .new:
            PainPrefill.latest(in: entries, notAfter: .now)
        }
        self.prefill = prefill
        _painBefore = State(initialValue: prefill?.severity ?? Severity(0)!)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    if active.isEmpty {
                        Text("No medications yet")
                            .accessibilityIdentifier("dose-no-medications")
                    }
                    ForEach(active) { medication in
                        medicationRow(medication)
                    }
                    Button("Add medication") {
                        isShowingNewMedication = true
                    }
                    .accessibilityIdentifier("dose-add-medication")
                }
                Section {
                    DateSection(date: $takenAt)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    SeveritySection(
                        caption: "Pain before",
                        spokenLabel: "Pain before",
                        idPrefix: "pain-before",
                        severity: $painBefore
                    )
                    .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    if let prefill {
                        prefillFootnote(for: prefill)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("PageBackground"))
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("log-dose-cancel")
                }
                if !medications.medications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink("Manage") {
                            MedicationsView(medications: medications)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("log-dose-manage")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    saveDose()
                } label: {
                    Text("Save dose")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(checkedID == nil)
                .accessibilityIdentifier("save-dose")
                .padding()
            }
            .alert("This dose could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .onChange(of: active) {
                selectedID = MedicationSelection.kept(selectedID, in: active)
            }
            .sheet(isPresented: $isShowingNewMedication) {
                MedicationFormView(medications: medications, onSaved: medicationSaved)
            }
            .sensoryFeedback(.selection, trigger: selectionTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
            .onAppear { medications.reload() }
        }
    }

    private var active: [Medication] {
        medications.active
    }

    private var checkedID: UUID? {
        MedicationSelection.kept(selectedID, in: active)
    }

    private func medicationRow(_ medication: Medication) -> some View {
        let isChecked = medication.id == checkedID
        return Button {
            select(medication)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(medication.listTitle)
                        .fontWeight(isChecked ? .semibold : .regular)
                    Text(medication.takenAs.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isChecked {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dose-medication-row")
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    private func prefillFootnote(for entry: Entry) -> some View {
        let note = PainPrefillNote(entry: entry, now: .now, calendar: .current, locale: .current)
        return Text(PrefillFootnoteText.text(for: note))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .cardCaption()
            .padding(.top, 8)
            .accessibilityIdentifier("pain-before-footnote")
    }

    private func saveDose() {
        guard let medication = active.first(where: { $0.id == checkedID }) else { return }
        var dose = Dose(id: doseID, medicationID: medication.id, takenAt: takenAt, painBefore: painBefore)
        dose.checkInAfter = medication.checkInAfter
        do {
            let logged = try doseSave.save(dose, log: medications.logDose)
            if logged {
                onSaved()
            }
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }

    private func select(_ medication: Medication) {
        guard medication.id != checkedID else { return }
        selectedID = medication.id
        selectionTicks += 1
    }

    /// The new medication is the newest, so it is last in the active list and becomes the chosen row. Choosing it
    /// does not tick, because the success haptic plays instead.
    private func medicationSaved() {
        selectedID = active.last?.id
        saveTicks += 1
    }
}
