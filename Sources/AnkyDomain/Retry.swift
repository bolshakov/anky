// SPDX-License-Identifier: GPL-3.0-or-later
/// How many times to try an action again after it throws, and how long to wait before each try.
public struct RetryPolicy: Equatable, Sendable {
    public let retries: Int
    public let delay: Duration

    public init(retries: Int, delay: Duration) {
        self.retries = retries
        self.delay = delay
    }

    public static let eraseAll = RetryPolicy(retries: 3, delay: .milliseconds(500))
}

/// Calls an action again after it throws. It prints and logs nothing, since an error can come from a store that holds
/// an entry.
public enum Retry {
    /// Returns at the first success. After the last attempt fails it rethrows that attempt's error. A throwing `sleep`
    /// ends the loop with its own error.
    @MainActor
    public static func run(
        _ policy: RetryPolicy,
        sleep: (Duration) async throws -> Void,
        action: () throws -> Void
    ) async throws {
        for _ in 0 ..< policy.retries {
            do {
                return try action()
            } catch {
                try await sleep(policy.delay)
            }
        }
        try action()
    }
}
