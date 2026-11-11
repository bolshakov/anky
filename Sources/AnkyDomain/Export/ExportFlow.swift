// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ExportFlow: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case idle
        case building(showsProgress: Bool)
        case sharing(URL)
        case failed
    }

    public static let progressDelay: Duration = .milliseconds(500)

    public private(set) var phase: Phase = .idle

    public init() {}

    public var isShowingProgress: Bool {
        phase == .building(showsProgress: true)
    }

    public var sharedFile: URL? {
        guard case let .sharing(file) = phase else { return nil }
        return file
    }

    public var isShowingFailure: Bool {
        phase == .failed
    }

    public mutating func tap() -> Bool {
        guard phase == .idle else { return false }
        phase = .building(showsProgress: false)
        return true
    }

    public mutating func progressDelayPassed() {
        guard phase == .building(showsProgress: false) else { return }
        phase = .building(showsProgress: true)
    }

    /// The error is dropped so nothing about it can reach the screen.
    public mutating func finish(_ result: Result<URL, any Error>) {
        guard case .building = phase else { return }
        switch result {
        case let .success(file): phase = .sharing(file)
        case .failure: phase = .failed
        }
    }

    public mutating func sheetClosed() -> URL? {
        guard let file = sharedFile else { return nil }
        phase = .idle
        return file
    }

    public mutating func failureDismissed() {
        guard phase == .failed else { return }
        phase = .idle
    }
}
