// SPDX-License-Identifier: GPL-3.0-or-later
public enum ScrollRestore {
    /// Distances are from the top of the content. A scroll that has come to rest at the top while a position was saved
    /// was sent there by the system, not by the person, so it goes back to the saved position.
    public static func target(offset: Double, saved: Double, isIdle: Bool) -> Double? {
        guard isIdle, offset <= 0, saved > 0 else { return nil }
        return saved
    }
}
