import AnkyDomain
import SwiftUI
import UIKit

struct KindSection: View {
    @Binding var draft: EntryDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(draft: Binding<EntryDraft>) {
        _draft = draft
        _ = Self.pickerAppearance
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            KindButtons(kind: $draft.kind)
        } else {
            Picker("Kind", selection: $draft.kind) {
                ForEach(EntryKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("kind-picker")
            .padding(4)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
        }
    }

    /// UIKit's appearance proxy is global, so it is set once for every segmented control the app makes.
    private static let pickerAppearance: Void = {
        let accent = UIColor(named: "AccentColor") ?? .tintColor
        let appearance = UISegmentedControl.appearance()
        appearance.setBackgroundImage(stretchableCapsule(.clear), for: .normal, barMetrics: .default)
        appearance.setBackgroundImage(capsule(accent.withAlphaComponent(0.15)), for: .selected, barMetrics: .default)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.boldSystemFont(ofSize: 17))
        appearance.setTitleTextAttributes([.foregroundColor: accent, .font: font], for: .selected)
    }()

    /// UIKit draws the selected pill itself, so it comes in as an image that follows light and dark mode.
    private static func capsule(_ color: UIColor) -> UIImage {
        let asset = UIImageAsset()
        for style in [UIUserInterfaceStyle.light, .dark] {
            let image = stretchableCapsule(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)))
            let styleTrait = UITraitCollection(userInterfaceStyle: style)
            let scaleTrait = UITraitCollection(displayScale: image.scale)
            asset.register(image, with: UITraitCollection(traitsFrom: [styleTrait, scaleTrait]))
        }
        return asset.image(with: UITraitCollection.current)
    }

    private static func stretchableCapsule(_ color: UIColor) -> UIImage {
        let side: CGFloat = 33
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: side, height: side), cornerRadius: side / 2).fill()
        }
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }
}
