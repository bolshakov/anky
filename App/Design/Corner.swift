import SwiftUI

/// The only place under `App/` that writes a corner radius as a number.
enum Corner {
    static let card: CGFloat = 22
}

extension Shape where Self == RoundedRectangle {
    static var card: RoundedRectangle {
        RoundedRectangle(cornerRadius: Corner.card)
    }
}
