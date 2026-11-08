// SPDX-License-Identifier: GPL-3.0-or-later
public enum RowSecondLine {
    public static let separator = " · "

    public static func text(time: String, detail: String?) -> String {
        guard let detail, !detail.isEmpty else { return time }
        return time + separator + detail
    }
}
