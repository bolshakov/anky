// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    /// The `.accessibility` shape makes VoiceOver report the box and not the control, which a frame alone does not.
    func minimumTapTarget() -> some View {
        frame(minWidth: Spacing.tapTarget, minHeight: Spacing.tapTarget)
            .contentShape([.interaction, .accessibility], Rectangle())
    }
}
