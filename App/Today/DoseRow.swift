// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseRow: View {
    let dose: Dose
    let readings: DoseReadings
    let title: String
    var isWaiting = false
    let onSelect: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var time: String {
        ClockText.text(for: dose.takenAt, calendar: .current, locale: .current)
    }

    private var spokenLabel: String {
        let label = DoseRowText.spokenLabel(time: time, title: title, readings: readings, words: .app)
        return isWaiting ? "\(label) \(String(localized: "Check in pending"))." : label
    }

    var body: some View {
        Button(action: onSelect) {
            layout
                // A concrete primary keeps the List button's tint off the hierarchical secondary texts below it.
                .foregroundStyle(Color.primary)
                .contentShape(Rectangle())
        }
        // The visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear.minimumTapTarget() }
                .accessibilityLabel(spokenLabel)
                .accessibilityHint(isWaiting ? String(localized: "Opens Check In") : "")
                .accessibilityIdentifier("dose-row")
        }
        // Outside the representation, so the label is its own element in the tree. It passes taps to the row.
        .overlay(alignment: checkInAlignment) {
            if isWaiting {
                checkInLabel
                    .frame(minWidth: Spacing.tapTarget, minHeight: Spacing.tapTarget, alignment: checkInAlignment)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Check in"))
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityIdentifier("check-in-label")
                    .allowsHitTesting(false)
            }
        }
    }

    /// At accessibility sizes the label takes its own last line, so no word is squeezed beside it. The hidden copy
    /// reserves that line and the overlay sits on it.
    private var layout: some View {
        IconRow(
            symbol: RowSymbol.dose,
            title: Text(title),
            time: time,
            detail: DoseRowText.painPhrase(for: readings, words: .app)
        ) {
            if isWaiting {
                checkInLabel.hidden()
            }
        }
    }

    private var checkInAlignment: Alignment {
        dynamicTypeSize.isAccessibilitySize ? .bottomLeading : .trailing
    }

    private var checkInLabel: some View {
        Text("Check in")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.tint)
    }
}
