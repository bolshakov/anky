// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// Writes only into the temporary directory, which iOS leaves out of device backups.
enum ExportBuild {
    static var folder: URL {
        FileManager.default.temporaryDirectory
    }

    static func archive(_ data: ExportData) async throws -> URL {
        let folder = folder
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        let build = info["CFBundleVersion"] as? String ?? ""
        let calendar = Calendar.current
        let hold = slowHold
        return try await Task.detached {
            try ExportArchive.removeLeftovers(in: folder)
            if let hold {
                try? await Task.sleep(for: hold)
            }
            return try ExportArchive.writeArchive(
                data, appVersion: version, build: build, now: .now, calendar: calendar, into: folder
            )
        }.value
    }

    private static var slowHold: Duration? {
        #if DEBUG
            ExportSlowSwitch.isOn(folder: EntriesLocation.folder()) ? ExportSlowSwitch.hold : nil
        #else
            nil
        #endif
    }
}
