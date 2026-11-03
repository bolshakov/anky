// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The Where row of Check In. It opens the place picker New Entry opens, on the places the draft holds.
struct CheckInWhereSection: View {
    @Binding var draft: EntryDraft
    let footer: String

    var body: some View {
        Section {
            NavigationLink {
                PlacesListView(draft: $draft)
            } label: {
                LabeledContent("Where") {
                    Text(value)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Where")
            .accessibilityValue(value)
            .accessibilityIdentifier("where-row")
        } footer: {
            Text(footer)
                .accessibilityIdentifier("where-footer")
        }
    }

    private var value: String {
        MorePlacesValue(selected: draft.places, chips: []).listText
    }
}
