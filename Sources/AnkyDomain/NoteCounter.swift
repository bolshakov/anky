public enum NoteCounter: Equatable, Sendable {
    case left(Int) // 1 to 39 characters left
    case limitReached // the note holds EntryDraft.noteLimit characters
}

public extension EntryDraft {
    var noteCounter: NoteCounter? {
        let left = Self.noteLimit - note.count
        if left <= 0 {
            return .limitReached
        }
        return left < 40 ? .left(left) : nil
    }
}
