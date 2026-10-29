import Foundation

/// Digits read the same in every language, so a test reads the number and never the words around it.
func leadingNumber(in text: String?) -> Int? {
    Int((text ?? "").prefix { $0.isNumber })
}

/// The first word that is a whole number. The pseudolanguage mangles the words around a number, so "4 of 10" in double
/// length reads "1$lld of 2$lld 4 of 10", and the first whole word is still 4.
func firstNumber(in text: String?) -> Int? {
    (text ?? "").split(whereSeparator: \.isWhitespace).lazy.compactMap { Int($0) }.first
}
