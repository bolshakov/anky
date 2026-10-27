import AnkyDomain
import SwiftUI
import UIKit

/// A multi-line field that stops at `EntryDraft.noteLimit` characters while the person types or pastes.
struct NoteTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> NoteUITextView {
        let view = NoteUITextView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: NoteUITextView, context _: Context) {
        if view.text != text {
            view.text = text
        }
        view.placeholder.isHidden = !text.isEmpty
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NoteUITextView, context _: Context) -> CGSize? {
        let width = proposal.width ?? 0
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: height)
    }
}

extension NoteTextView {
    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        /// Keeps the part of a long insertion that fits, so a paste stops at the limit instead of vanishing.
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            let current = textView.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let roomLeft = EntryDraft.noteLimit - (current.count - current[swiftRange].count)
            if replacement.count <= roomLeft {
                return true
            }
            let accepted = String(replacement.prefix(max(roomLeft, 0)))
            textView.textStorage.replaceCharacters(in: range, with: accepted)
            textView.selectedRange = NSRange(location: range.location + accepted.utf16.count, length: 0)
            textViewDidChange(textView)
            return false
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text ?? ""
            (textView as? NoteUITextView)?.placeholder.isHidden = textView.hasText
        }
    }
}

final class NoteUITextView: UITextView {
    let placeholder = UILabel()

    init() {
        super.init(frame: .zero, textContainer: nil)
        font = .preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true
        textColor = .label
        backgroundColor = .clear
        isScrollEnabled = false
        textContainerInset = UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)
        textContainer.lineFragmentPadding = 0
        accessibilityLabel = "Add a note"
        accessibilityIdentifier = "note-field"

        placeholder.text = "Add a note"
        placeholder.font = font
        placeholder.adjustsFontForContentSizeCategory = true
        placeholder.textColor = .placeholderText
        placeholder.isAccessibilityElement = false
        addSubview(placeholder)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("NoteUITextView is built in code only")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = textContainerInset
        let width = bounds.width - inset.left - inset.right
        let height = placeholder.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        placeholder.frame = CGRect(x: inset.left, y: inset.top, width: width, height: height)
    }
}
