import Foundation
import MasterMailCore
import Testing

@MainActor
struct SessionRestorationTests {
    private func app(_ fixture: HTTPFixture, graph: GraphClient) throws -> AppModel {
        AppModel(store: try MailStore.inMemory(),
                 aiSettings: AISettingsStore(fileURL: fixture.directory.appendingPathComponent("ai.json")),
                 queue: ActionQueue(fileURL: fixture.directory.appendingPathComponent("queue.json")),
                 client: graph, configureAutomatically: false)
    }

    @Test func startupFailureOffersRetryWithoutAskingForMicrosoftLogin() async throws {
        let fixture = HTTPFixture([.init(status: 503)])
        let graph = try fixture.graph()
        let model = try app(fixture, graph: graph)
        await model.restoreSession()
        #expect(model.phase == .sessionUnavailable)
        #expect(await graph.isSignedIn)
        #expect(model.errorMessage == nil)
        await model.signOut()
        #expect(model.phase == .signedOut)
    }

    @Test func startupWithRevokedAuthorizationRequestsNewLogin() async throws {
        let fixture = HTTPFixture([.init(status: 400, body: #"{"error":"invalid_grant"}"#)])
        let graph = try fixture.graph(expired: true)
        let model = try app(fixture, graph: graph)
        await model.restoreSession()
        #expect(model.phase == .signedOut)
        #expect(await graph.isSignedIn == false)
    }

    @Test func signingOutDuringRestorationCannotRestoreSession() async throws {
        let fixture = HTTPFixture([.init(body: #"{"id":"test-account","mail":"person@example.test"}"#, delay: .milliseconds(100))])
        let graph = try fixture.graph()
        let model = try app(fixture, graph: graph)
        let restoration = Task { await model.restoreSession() }
        while fixture.requests.isEmpty { await Task.yield() }
        await model.signOut()
        await restoration.value
        #expect(model.phase == .signedOut)
        #expect(model.accountEmail.isEmpty)
    }
}
