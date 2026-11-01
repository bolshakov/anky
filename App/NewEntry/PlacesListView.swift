// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI
import TipKit

struct PlacesListView: View {
    @Binding var draft: EntryDraft
    @Environment(\.dismiss) private var dismiss
    @Environment(TipProgressModel.self) private var tipProgress
    @State private var query = ""

    var body: some View {
        let found = Set(
            PlaceSearch.joints(
                matching: query,
                jointName: { String(localized: $0.displayName) },
                groupName: { String(localized: $0.displayName) }
            )
        )
        List {
            Section {
                TipView(PinShortcutTip())
                    .tipViewStyle(PinTipStyle())
                    .accessibilityIdentifier("pin-tip")
                    .listRowInsets(.horizontal, 0)
            }
            .listRowBackground(Color.clear)
            ForEach(PlaceGroup.allCases, id: \.self) { group in
                let joints = PlaceCatalog.joints(in: group).filter(found.contains)
                if !joints.isEmpty {
                    Section {
                        ForEach(joints.flatMap(\.places), id: \.self) { place in
                            PlaceListRow(place: place, draft: $draft)
                        }
                    } header: {
                        Text(group.displayName)
                            .cardCaption()
                    }
                }
            }
            if found.isEmpty {
                Text("No matching places")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Where")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search joints and places")
        .onAppear {
            tipProgress.recordVisit()
        }
        .safeAreaInset(edge: .bottom) {
            DonePlacesButton(count: draft.placeCount) {
                dismiss()
            }
            .padding()
        }
    }
}
