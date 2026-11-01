// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationRow: View {
    let medication: Medication
    var showsChevron = true

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(medication.listTitle)
                    .fixedSize(horizontal: false, vertical: true)
                Text(medication.takenAs.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
