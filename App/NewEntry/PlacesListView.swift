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
                    .nonCardBlock()
            }
            ForEach(PlaceGroup.allCases, id: \.self) { group in
                let joints = PlaceCatalog.joints(in: group).filter(found.contains)
                if !joints.isEmpty {
                    CardSection(Text(group.displayName), id: "place-group-\(group)") {
                        ForEach(joints.flatMap(\.places), id: \.self) { place in
                            PlaceListRow(place: place, draft: $draft)
                                .rowHeight()
                        }
                    }
                }
            }
            if found.isEmpty {
                Text("No matching places")
                    .foregroundStyle(.secondary)
                    .nonCardBlock()
            }
        }
        .screenSpacing()
        .navigationTitle("Where")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search joints and places")
        .onAppear {
            tipProgress.recordVisit()
        }
        .safeAreaBar(edge: .bottom) {
            doneButton
        }
    }

    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            doneTitle.frame(maxWidth: .infinity, minHeight: Spacing.primaryButtonLabelHeight)
        }
        .primaryButton()
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.bottom, Spacing.bottomClearance)
        .accessibilityLabel(spokenDoneTitle)
        .accessibilityIdentifier("done-places")
    }

    private var doneTitle: Text {
        draft.placeCount == 0 ? Text("Done") : Text("Done · \(draft.placeCount) places")
    }

    private var spokenDoneTitle: String {
        let done = String(localized: "Done")
        guard draft.placeCount > 0 else { return done }
        return [done, String(localized: "\(draft.placeCount) places")].joined(separator: ", ")
    }
}
