import EventKit
@testable import MasterMailCore
import Testing

@MainActor
struct CalendarPermissionTests {
    @Test func previouslyGrantedPermissionDoesNotRequestAgain() async {
        var calls = 0
        let permission = EventKitPermission(authorization: { .fullAccess }, request: { calls += 1; return true })
        #expect(await permission.requestAccess())
        #expect(await permission.requestAccess())
        #expect(calls == 0)
    }

    @Test(arguments: [EKAuthorizationStatus.denied, .restricted, .writeOnly])
    func deniedOrLimitedPermissionDoesNotKeepAsking(status: EKAuthorizationStatus) async {
        var calls = 0
        let permission = EventKitPermission(authorization: { status }, request: { calls += 1; return true })
        #expect(await permission.requestAccess() == false)
        #expect(await permission.requestAccess() == false)
        #expect(calls == 0)
    }

    @Test func concurrentRequestsShareOnePermissionPrompt() async throws {
        var status = EKAuthorizationStatus.notDetermined
        var calls = 0
        let permission = EventKitPermission(authorization: { status }, request: {
            calls += 1
            try await Task.sleep(for: .milliseconds(30))
            status = .fullAccess
            return true
        })
        let first = Task { await permission.requestAccess() }
        let second = Task { await permission.requestAccess() }
        #expect(await first.value)
        #expect(await second.value)
        #expect(await permission.requestAccess())
        #expect(calls == 1)
    }

    @Test func revocationIsRespectedWithoutShowingAnotherPrompt() async {
        var status = EKAuthorizationStatus.fullAccess
        var calls = 0
        let permission = EventKitPermission(authorization: { status }, request: { calls += 1; return true })
        #expect(await permission.requestAccess())
        status = .denied
        #expect(await permission.requestAccess() == false)
        #expect(calls == 0)
    }
}
