import Foundation

/// Digits read the same in every language, so a test reads the number and never the words around it.
func leadingNumber(in text: String?) -> Int? {
    Int((text ?? "").prefix { $0.isNumber })
}
