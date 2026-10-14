import Foundation
import MasterMailCore
import Testing

@MainActor
struct ComposeReliabilityTests {
    private func app(_ fixture: HTTPFixture) throws -> AppModel {
        AppModel(store: try MailStore.inMemory(),
                 aiSettings: AISettingsStore(fileURL: fixture.directory.appendingPathComponent("ai.json")),
                 queue: ActionQueue(fileURL: fixture.directory.appendingPathComponent("queue.json")),
                 configureAutomatically: false)
    }

    @Test func twoPendingSendsBothComplete() async throws {
        let fixture = HTTPFixture([.init(body: HTTPFixture.message("d1")), .init(body: HTTPFixture.message("d2")), .init(), .init(), .init(status: 202), .init(status: 202)])
        let graph = try fixture.graph()
        let first = ComposeModel(mode: .new, graph: graph)
        let second = ComposeModel(mode: .new, graph: graph)
        await first.start(); await second.start()
        first.to = "one@example.test"; second.to = "two@example.test"
        let app = try app(fixture)
        await app.scheduleSend(first, delay: .milliseconds(150))
        await app.scheduleSend(second, delay: .milliseconds(150))
        #expect(app.pendingSendCount == 2)
        try await Task.sleep(for: .milliseconds(400))
        #expect(app.pendingSendCount == 0)
        #expect(app.failedSends.isEmpty)
        #expect(app.undoStack.isEmpty)
        #expect(fixture.requests.filter { $0.url?.path.hasSuffix("/send") == true }.count == 2)
    }

    @Test func undoCancelsOnlyItsSendAfterSavingTheDraft() async throws {
        let fixture = HTTPFixture([.init(body: HTTPFixture.message("d1")), .init()])
        let model = ComposeModel(mode: .new, graph: try fixture.graph())
        await model.start()
        model.to = "one@example.test"; model.body = AttributedString("Texto que precisa ficar salvo")
        let app = try app(fixture)
        await app.scheduleSend(model, delay: .milliseconds(100))
        #expect(model.savedAt != nil)
        await app.undo()
        try await Task.sleep(for: .milliseconds(180))
        #expect(app.pendingSendCount == 0)
        #expect(fixture.requests.contains { $0.httpMethod == "PATCH" })
        #expect(!fixture.requests.contains { $0.url?.path.hasSuffix("/send") == true })
    }

    @Test func successfulRetryClearsThePreviousErrorAndOutbox() async throws {
        let fixture = HTTPFixture([.init(body: HTTPFixture.message("d1")), .init(), .init(status: 500), .init(status: 202)])
        let model = ComposeModel(mode: .new, graph: try fixture.graph())
        await model.start(); model.to = "one@example.test"
        let app = try app(fixture)
        await app.scheduleSend(model, delay: .milliseconds(10))
        try await Task.sleep(for: .milliseconds(100))
        let failed = try #require(app.failedSends.first)
        #expect(model.error != nil)
        await app.retrySend(failed)
        #expect(model.error == nil)
        #expect(app.failedSends.isEmpty)
    }

    @Test func saveFailureKeepsTheEditorOpenAndDoesNotScheduleSend() async throws {
        let fixture = HTTPFixture([.init(body: HTTPFixture.message("d1")), .init(status: 500)])
        let model = ComposeModel(mode: .new, graph: try fixture.graph())
        await model.start(); model.to = "one@example.test"
        let app = try app(fixture); app.compose = model
        await app.scheduleSend(model, delay: .milliseconds(10))
        #expect(app.compose?.id == model.id)
        #expect(app.pendingSendCount == 0)
        #expect(model.error != nil)
    }

    @Test func sendWithoutRecipientsIsDisabled() async throws {
        let fixture = HTTPFixture([.init(body: HTTPFixture.message("d1"))])
        let model = ComposeModel(mode: .new, graph: try fixture.graph())
        await model.start()
        #expect(!model.canSend)
        #expect(await model.prepareForSend() == false)
        #expect(fixture.requests.count == 1)
    }
    @Test func signingOutDuringBodyDownloadCannotUpdateAnEmptyConversation() async throws {
        let fixture = HTTPFixture([.init(body: #"{"body":{"contentType":"html","content":"<p>Corpo</p>"}}"#, delay: .milliseconds(80))])
        let store = try MailStore.inMemory()
        let app = AppModel(store: store,
                           aiSettings: AISettingsStore(fileURL: fixture.directory.appendingPathComponent("ai.json")),
                           queue: ActionQueue(fileURL: fixture.directory.appendingPathComponent("queue.json")),
                           client: try fixture.graph(), configureAutomatically: false)
        let raw = HTTPFixture.message("old").replacingOccurrences(of: "\"isRead\":false", with: "\"isRead\":true")
        let message = StoredMessage(message: try GraphClient.decoder.decode(Message.self, from: Data(raw.utf8)), folder: "inbox")
        try store.upsert([message])
        let opening = Task { await app.open(message) }
        while fixture.requests.isEmpty { await Task.yield() }
        await app.signOut()
        await opening.value
        #expect(app.conversation.isEmpty)
        #expect(app.openMessage == nil)
    }

    @Test func failedEventCreationKeepsTheDraftAvailable() async throws {
        let fixture = HTTPFixture([.init(status: 500)])
        let calendar = CalendarModel(graph: try fixture.graph())
        let draft = EventDraft(title: "Reunião", start: Date(), end: Date().addingTimeInterval(3600))
        #expect(await calendar.create(draft) == false)
        #expect(calendar.error != nil)
    }

}
