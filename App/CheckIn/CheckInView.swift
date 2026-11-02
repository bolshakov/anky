// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct CheckInView: View {
    let dose: Dose
    let title: String
    let readings: DoseReadings
    let now: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
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
                .padding()
            }
            .background(Color("PageBackground"))
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
        }
    }

    private var infoTitle: String {
        CheckInText.infoTitle(title: title)
    }

    private var infoDetail: String {
        let time = ClockText.text(for: dose.takenAt, calendar: .current, locale: .current)
        let taken = CheckInText.infoTaken(time: time, day: CheckInDay(dose.takenAt, now: now))
        guard let before = readings.before else { return taken }
        return "\(taken) \(CheckInText.infoPain(before))"
    }
}
