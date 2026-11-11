// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ExportTime {
    public static func utc(_ date: Date) -> String {
        date.formatted(.iso8601)
    }
}
