// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiQuestionBlock: View {
    let question: BasdaiQuestion
    @Binding var answer: BasdaiAnswer
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Dimmed by opacity and not `.disabled`, since a disabled slider would take no first touch to answer it.
    private static let unansweredOpacity = 0.4

    var body: some View {
        CardSection(id: "basdai-q\(question.number)") {
            VStack(alignment: .leading, spacing: Spacing.cardContentGap) {
                heading
                    .accessibilityHidden(true)
                VStack(spacing: Spacing.tightGap) {
                    slider
                    BasdaiEndLabels(question: question)
                }
            }
        }
    }

    private var slider: some View {
        Slider(value: level, in: 0 ... 10, step: 1) {
            EmptyView()
        } onEditingChanged: { isEditing in
            if isEditing {
                answer = answer.touched()
            }
        }
        // Inside the scrolling form a tap on the thumb ends before the slider starts editing, so the tap answers too.
        .simultaneousGesture(TapGesture().onEnded { answer = answer.touched() })
        .opacity(answer.value == nil ? Self.unansweredOpacity : 1)
        .minimumTapTarget()
        .accessibilityLabel(Text(verbatim: question.text))
        .accessibilityValue(Text(verbatim: question.spokenText(answer, locale: locale)))
        .accessibilityIdentifier("basdai-q\(question.number)-slider")
        .sensoryFeedback(.selection, trigger: answer)
    }

    /// The question wraps over several lines, so a layout picked by its one-line width would always stack. The value
    /// moves under the question at the accessibility sizes instead.
    private var heading: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.tightGap))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.inlineGap))
        return layout {
            Text(wording)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            Text(verbatim: question.valueText(answer, locale: locale))
                .fixedSize()
                .accessibilityIdentifier("basdai-q\(question.number)-value")
        }
    }

    private var wording: AttributedString {
        question.wording.reduce(into: AttributedString()) { text, segment in
            var part = AttributedString(segment.text)
            if segment.isBold {
                part.inlinePresentationIntent = .stronglyEmphasized
            }
            text += part
        }
    }

    private var level: Binding<Double> {
        Binding(
            get: { Double(answer.value ?? 0) },
            set: { answer = answer.slid(to: Int($0)) }
        )
    }
}

private struct BasdaiEndLabels: View {
    let question: BasdaiQuestion

    var body: some View {
        HStack {
            Text(verbatim: question.lowLabel)
            Spacer()
            Text(verbatim: question.highLabel)
        }
        .overlay {
            if let mid = question.midLabel {
                Text(verbatim: mid)
            }
        }
        .font(.footnote)
        .foregroundStyle(Color.ink2)
        .accessibilityHidden(true)
    }
}
