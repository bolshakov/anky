import AnkyDomain
import SwiftUI
import UIKit

struct KindSection: View {
    @Binding var draft: EntryDraft

    init(draft: Binding<EntryDraft>) {
        _draft = draft
        _ = Self.pickerAppearance
    }

    var body: some View {
        Picker("Kind", selection: $draft.kind) {
            ForEach(EntryKind.allCases, id: \.self) { kind in
                Text(kind.title).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityIdentifier("kind-picker")
    }

    /// UIKit's appearance proxy is global, so it is set once for every segmented control the app makes.
    private static let pickerAppearance: Void = {
        let accent = UIColor(named: "AccentColor") ?? .tintColor
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = accent.withAlphaComponent(0.15)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        appearance.setTitleTextAttributes(
            [.foregroundColor: accent, .font: UIFont.boldSystemFont(ofSize: 17)],
            for: .selected
        )
    }()
}
