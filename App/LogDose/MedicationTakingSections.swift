// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationTakingSections: View {
    @Binding var draft: MedicationDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CardSection(Text("How you take it"), id: "taking") {
            if dynamicTypeSize.isAccessibilitySize {
                TakenAsMenuRow(takenAs: $draft.takenAs)
            } else {
                Picker("How you take it", selection: $draft.takenAs) { options }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("taken-as")
                    .nonCardBlock()
            }
        }
        MedicationCheckInSection(checkIn: $draft.checkIn)
    }

    private var options: some View {
        ForEach(TakenAs.allCases, id: \.self) { option in
            Text(option.title).tag(option)
        }
    }
}

private struct TakenAsMenuRow: View {
    @Binding var takenAs: TakenAs

    var body: some View {
        Menu {
            Picker("How you take it", selection: $takenAs) {
                ForEach(TakenAs.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
            .labelsHidden()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.tightGap) {
                Text("How you take it")
                    .foregroundStyle(Color.ink)
                HStack {
                    Text(takenAs.title)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundStyle(Color.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .rowHeight()
        .accessibilityLabel("How you take it")
        .accessibilityValue(Text(takenAs.title))
        .accessibilityIdentifier("taken-as")
    }
}
