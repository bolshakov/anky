// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only. Counts erase attempts and not store writes, so a walk's seed cannot spend the count.
    @MainActor
    enum EraseFailureSwitch {
        enum Stage: String {
            case entries, medications, basdai
        }

        struct Refused: Error {}

        private static var failuresLeft = ProcessInfo.processInfo.environment["ANKY_FAIL_ERASE"].flatMap(Int.init) ?? 0
        private static let failingStage = ProcessInfo.processInfo.environment["ANKY_FAIL_ERASE_STORE"]
            .flatMap(Stage.init) ?? .basdai

        static func check(_ stage: Stage) throws {
            guard stage == failingStage, failuresLeft > 0 else { return }
            failuresLeft -= 1
            throw Refused()
        }
    }
#endif
