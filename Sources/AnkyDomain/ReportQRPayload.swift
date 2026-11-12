// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// What the report's QR code encodes: the Anky site, which links to the App Store. A fixed string, never data from
/// the log.
public enum ReportQRPayload {
    public static let url = "https://anky.bolshakov.dev"
    public static let label = "QR code: anky.bolshakov.dev"
}
