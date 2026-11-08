// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import TipKit

struct PinTipStyle: TipViewStyle {
    private enum Metrics {
        static let dismissTarget: CGFloat = 44
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: Spacing.tipGap) {
            Image(systemName: "pin.fill")
                .font(.body.weight(.semibold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.tightGap) {
                configuration.title
                    .font(.headline)
                configuration.message?
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                configuration.tip.invalidate(reason: .tipClosed)
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .frame(width: Metrics.dismissTarget, height: Metrics.dismissTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss tip")
        }
        .foregroundStyle(Color("OnSoftAccent"))
        .padding(.leading, Spacing.tipGap)
        .padding(.vertical, Spacing.tipInset)
        .padding(.trailing, Spacing.tipInset)
        .background(Color("SoftAccent"), in: .card)
        .accessibilityElement(children: .contain)
    }
}
