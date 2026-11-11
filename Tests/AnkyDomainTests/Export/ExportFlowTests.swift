// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ExportFlowTests {
    private struct BuildFailed: Error {}

    private let file = URL(filePath: "/tmp/anky-2026-11-12.zip")
    private let otherFile = URL(filePath: "/tmp/anky-other.zip")

    private func building() -> ExportFlow {
        var flow = ExportFlow()
        _ = flow.tap()
        return flow
    }

    private func sharing() -> ExportFlow {
        var flow = building()
        flow.finish(.success(file))
        return flow
    }

    private func failed() -> ExportFlow {
        var flow = building()
        flow.finish(.failure(BuildFailed()))
        return flow
    }

    @Test func aNewFlowIsIdleAndShowsNothing() {
        let flow = ExportFlow()
        #expect(flow.phase == .idle)
        #expect(!flow.isShowingProgress)
        #expect(flow.sharedFile == nil)
        #expect(!flow.isShowingFailure)
    }

    @Test func theProgressDelayIsHalfASecond() {
        #expect(ExportFlow.progressDelay == .milliseconds(500))
    }

    @Test func aTapWhileIdleStartsABuildWithoutProgress() {
        var flow = ExportFlow()
        let started = flow.tap()
        #expect(started)
        #expect(flow.phase == .building(showsProgress: false))
        #expect(!flow.isShowingProgress)
    }

    @Test func aSecondTapWhileBuildingIsIgnored() {
        var flow = building()
        let started = flow.tap()
        #expect(!started)
        #expect(flow == building())
    }

    @Test func aTapWhileTheProgressShowsIsIgnored() {
        var flow = building()
        flow.progressDelayPassed()
        let before = flow
        let started = flow.tap()
        #expect(!started)
        #expect(flow == before)
    }

    @Test func aTapWhileSharingIsIgnored() {
        var flow = sharing()
        let started = flow.tap()
        #expect(!started)
        #expect(flow.sharedFile == file)
    }

    @Test func aTapWhileTheFailureShowsIsIgnored() {
        var flow = failed()
        let started = flow.tap()
        #expect(!started)
        #expect(flow.isShowingFailure)
    }

    @Test func aQuickDoubleTapBuildsOnceAndOpensOneSheet() {
        var flow = ExportFlow()
        let builds = [flow.tap(), flow.tap()].filter(\.self).count
        flow.finish(.success(file))
        flow.finish(.success(otherFile))
        #expect(builds == 1)
        #expect(flow.sharedFile == file)
        let first = flow.sheetClosed()
        let second = flow.sheetClosed()
        #expect(first == file)
        #expect(second == nil)
    }

    @Test func theProgressShowsOnceTheDelayPasses() {
        var flow = building()
        flow.progressDelayPassed()
        #expect(flow.phase == .building(showsProgress: true))
        #expect(flow.isShowingProgress)
    }

    @Test func theDelayArrivingAfterTheBuildFinishedChangesNothing() {
        var flow = sharing()
        flow.progressDelayPassed()
        #expect(flow == sharing())
        #expect(!flow.isShowingProgress)
    }

    @Test func theDelayArrivingAfterTheBuildFailedChangesNothing() {
        var flow = failed()
        flow.progressDelayPassed()
        #expect(flow == failed())
    }

    @Test func theDelayArrivingWhileIdleChangesNothing() {
        var flow = ExportFlow()
        flow.progressDelayPassed()
        #expect(flow == ExportFlow())
    }

    @Test func aSuccessfulBuildOpensTheSheetForItsFile() {
        var flow = building()
        flow.progressDelayPassed()
        flow.finish(.success(file))
        #expect(flow.phase == .sharing(file))
        #expect(flow.sharedFile == file)
        #expect(!flow.isShowingProgress)
        #expect(!flow.isShowingFailure)
    }

    @Test func aFailedBuildSetsTheAlertStateAndNoSheet() {
        var flow = building()
        flow.progressDelayPassed()
        flow.finish(.failure(BuildFailed()))
        #expect(flow.phase == .failed)
        #expect(flow.isShowingFailure)
        #expect(flow.sharedFile == nil)
        #expect(!flow.isShowingProgress)
    }

    @Test func aBuildThatThrowsLeavesTheAlertStateAndNoSharedFile() {
        var flow = ExportFlow()
        _ = flow.tap()
        flow.finish(Result { throw BuildFailed() })
        #expect(flow.isShowingFailure)
        #expect(flow.sharedFile == nil)
    }

    @Test func aFinishOutsideABuildChangesNothing() {
        var idle = ExportFlow()
        idle.finish(.success(file))
        #expect(idle == ExportFlow())

        var shown = sharing()
        shown.finish(.failure(BuildFailed()))
        #expect(shown == sharing())

        var alert = failed()
        alert.finish(.success(file))
        #expect(alert == failed())
    }

    @Test func closingTheSheetReturnsTheFileToDeleteOnce() {
        var flow = sharing()
        let first = flow.sheetClosed()
        #expect(first == file)
        #expect(flow.phase == .idle)
        let second = flow.sheetClosed()
        #expect(second == nil)
    }

    @Test func closingTheSheetOutsideSharingReturnsNothing() {
        var idle = ExportFlow()
        let fromIdle = idle.sheetClosed()
        #expect(fromIdle == nil)
        #expect(idle == ExportFlow())

        var busy = building()
        let fromBuilding = busy.sheetClosed()
        #expect(fromBuilding == nil)
        #expect(busy == building())

        var alert = failed()
        let fromFailure = alert.sheetClosed()
        #expect(fromFailure == nil)
        #expect(alert == failed())
    }

    @Test func aTapAfterTheSheetClosedStartsANewBuild() {
        var flow = sharing()
        _ = flow.sheetClosed()
        let started = flow.tap()
        #expect(started)
        #expect(flow.phase == .building(showsProgress: false))
    }

    @Test func dismissingTheFailureReturnsToIdle() {
        var flow = failed()
        flow.failureDismissed()
        #expect(flow == ExportFlow())
        let started = flow.tap()
        #expect(started)
    }

    @Test func dismissingTheFailureOutsideTheFailureChangesNothing() {
        var busy = building()
        busy.failureDismissed()
        #expect(busy == building())

        var shown = sharing()
        shown.failureDismissed()
        #expect(shown == sharing())
    }
}
