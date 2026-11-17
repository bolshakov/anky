// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

@MainActor
struct RetryTests {
    private struct Failure: Error, Equatable {
        let attempt: Int
    }

    private struct SleepInterrupted: Error, Equatable {}

    private final class Recorder {
        var attempts = 0
        var delays: [Duration] = []

        func sleep(_ delay: Duration) {
            delays.append(delay)
        }

        func failing(untilAttempt firstSuccess: Int) throws {
            attempts += 1
            if attempts < firstSuccess {
                throw Failure(attempt: attempts)
            }
        }
    }

    private let policy = RetryPolicy(retries: 3, delay: .milliseconds(250))

    @Test func eraseAllRetriesThreeTimesHalfASecondApart() {
        #expect(RetryPolicy.eraseAll == RetryPolicy(retries: 3, delay: .milliseconds(500)))
    }

    @Test func firstSuccessReturnsAfterOneAttemptWithoutSleeping() async throws {
        let recorder = Recorder()

        try await Retry.run(policy, sleep: recorder.sleep) { try recorder.failing(untilAttempt: 1) }

        #expect(recorder.attempts == 1)
        #expect(recorder.delays.isEmpty)
    }

    @Test func successOnTheLastRetryStopsThere() async throws {
        let recorder = Recorder()

        try await Retry.run(policy, sleep: recorder.sleep) { try recorder.failing(untilAttempt: 4) }

        #expect(recorder.attempts == 4)
        #expect(recorder.delays.count == 3)
    }

    @Test func successAfterTwoFailuresSleepsTheDelayBeforeEachRetry() async throws {
        let recorder = Recorder()

        try await Retry.run(policy, sleep: recorder.sleep) { try recorder.failing(untilAttempt: 3) }

        #expect(recorder.attempts == 3)
        #expect(recorder.delays == [.milliseconds(250), .milliseconds(250)])
    }

    @Test func persistentFailureTriesOnceMoreThanRetriesAndSleepsOnlyBetweenAttempts() async {
        let recorder = Recorder()

        _ = try? await Retry.run(policy, sleep: recorder.sleep) { try recorder.failing(untilAttempt: .max) }

        #expect(recorder.attempts == 4)
        #expect(recorder.delays.count == 3)
    }

    @Test func persistentFailureRethrowsTheErrorOfTheLastAttempt() async {
        let recorder = Recorder()

        await #expect(throws: Failure(attempt: 4)) {
            try await Retry.run(policy, sleep: recorder.sleep) { try recorder.failing(untilAttempt: .max) }
        }
    }

    @Test func noRetriesMeansOneAttemptAndNoSleep() async {
        let recorder = Recorder()
        let once = RetryPolicy(retries: 0, delay: .seconds(1))

        await #expect(throws: Failure(attempt: 1)) {
            try await Retry.run(once, sleep: recorder.sleep) { try recorder.failing(untilAttempt: .max) }
        }

        #expect(recorder.attempts == 1)
        #expect(recorder.delays.isEmpty)
    }

    @Test func sleeperThatThrowsEndsTheLoopWithItsError() async {
        let recorder = Recorder()

        await #expect(throws: SleepInterrupted()) {
            try await Retry.run(
                policy,
                sleep: { _ in throw SleepInterrupted() },
                action: { try recorder.failing(untilAttempt: .max) }
            )
        }

        #expect(recorder.attempts == 1)
    }
}
