import SwiftUI
import TipKit

struct PinTipStyle: TipViewStyle {
    private enum Metrics {
        static let dismissTarget: CGFloat = 44
        static let spacing: CGFloat = 12
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: Metrics.spacing) {
            Image(systemName: "pin.fill")
                .font(.body.weight(.semibold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
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
        .padding(.leading, Metrics.spacing)
        .padding(.vertical, 4)
        .padding(.trailing, 4)
        .background(Color("SoftAccent"), in: .card)
        .accessibilityElement(children: .contain)
    }
}
