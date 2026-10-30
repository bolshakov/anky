import AnkyDomain
import SwiftUI

struct PlacesListView: View {
    @Binding var draft: EntryDraft
    @Environment(\.dismiss) private var dismiss
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
            ForEach(PlaceGroup.allCases, id: \.self) { group in
                let joints = PlaceCatalog.joints(in: group).filter(found.contains)
                if !joints.isEmpty {
                    Section {
                        ForEach(joints, id: \.self) { joint in
                            PlaceListRow(joint: joint, draft: $draft)
                        }
                    } header: {
                        Text(group.displayName)
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
        .safeAreaInset(edge: .bottom) {
            DonePlacesButton(count: draft.placeCount) {
                dismiss()
            }
            .padding()
        }
    }
}
