// SPDX-License-Identifier: GPL-3.0-or-later
public struct ContentEdges: Equatable, Sendable {
    public let leading: Double
    public let trailing: Double

    public init(leading: Double, trailing: Double) {
        self.leading = leading
        self.trailing = trailing
    }
}

public enum ContentColumn {
    /// Distances from the screen's physical edges, never a sum of margin and inset.
    public static func edges(
        width: Double, leadingInset: Double, trailingInset: Double, margin: Double, maximumWidth: Double
    ) -> ContentEdges {
        let centring = max(0, (width - maximumWidth) / 2)
        return ContentEdges(
            leading: max(margin, leadingInset, centring),
            trailing: max(margin, trailingInset, centring)
        )
    }
}
