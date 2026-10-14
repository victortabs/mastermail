import Foundation
@testable import MasterMailCore
import Testing

struct SyncRecoveryTests {
    private let completedPage = #"{"value":[],"@odata.deltaLink":"https://graph.microsoft.com/v1.0/completed?$deltatoken=test"}"#

    @Test func readStateOnlyDeltaPreservesMessageAndLocalOrganization() async throws {
        let fixture = HTTPFixture([.init(body: ##"{"value":[{"@odata.type":"#microsoft.graph.message","id":"saved","isRead":true}],"@odata.deltaLink":"https://graph.microsoft.com/v1.0/completed?$deltatoken=test"}"##)])
        let store = try MailStore.inMemory()
        var message = StoredMessage(message: try GraphClient.decoder.decode(Message.self, from: Data(HTTPFixture.message("saved").utf8)), folder: "inbox")
        message.localFolder = "Projetos"; message.bodyHTML = "<p>Texto salvo</p>"
        message.tipo = Tipo.pessoa.rawValue
        try store.upsert([message])
        try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
        message.isRead = true
        #expect(try store.message(id: "saved") == message)
        #expect(fixture.requests.count == 1)
        #expect(try store.isFullyIndexed(folder: "inbox"))
    }

    @Test func partialDeltaKeepsPendingLocalReadAction() async throws {
        let fixture = HTTPFixture([.init(body: #"{"value":[{"id":"saved","isRead":true}],"@odata.deltaLink":"https://graph.microsoft.com/v1.0/completed?$deltatoken=test"}"#)])
        let store = try MailStore.inMemory()
        let message = StoredMessage(message: try GraphClient.decoder.decode(Message.self, from: Data(HTTPFixture.message("saved").utf8)), folder: "inbox")
        try store.upsert([message])
        let queue = ActionQueue(fileURL: fixture.directory.appendingPathComponent("queue.json"))
        try await queue.enqueue(.markRead(id: "saved", isRead: false))
        try await MailSync(graph: fixture.graph(), store: store, queue: queue).sync(folder: "inbox")
        #expect(try store.message(id: "saved")?.isRead == false)
    }

    @Test func partialDeltaForUnknownMessageLoadsFullMessage() async throws {
        let fixture = HTTPFixture([
            .init(body: #"{"value":[{"id":"new","isRead":true}],"@odata.deltaLink":"https://graph.microsoft.com/v1.0/completed?$deltatoken=test"}"#),
            .init(body: HTTPFixture.message("new")),
        ])
        let store = try MailStore.inMemory()
        try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
        #expect(try store.message(id: "new")?.subject == "Teste")
        #expect(fixture.requests.last?.url?.path == "/v1.0/me/messages/new")
    }

    @Test func messageDeletedBeforeHydrationDoesNotStopSync() async throws {
        let fixture = HTTPFixture([
            .init(body: #"{"value":[{"id":"gone","isRead":true}],"@odata.deltaLink":"https://graph.microsoft.com/v1.0/completed?$deltatoken=test"}"#),
            .init(status: 404),
        ])
        let store = try MailStore.inMemory()
        try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
        #expect(try store.isFullyIndexed(folder: "inbox"))
        #expect(try store.message(id: "gone") == nil)
    }

    @Test func syncSelectsOnlyFieldsAvailableOnOrdinaryMessages() async throws {
        let fixture = HTTPFixture([.init(body: completedPage)])
        let store = try MailStore.inMemory()
        try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
        let request = try #require(fixture.requests.first)
        let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let fields = try #require(query.first { $0.name == "$select" }?.value).split(separator: ",")
        #expect(!fields.contains("meetingMessageType"))
        #expect(fields.contains("receivedDateTime") && fields.contains("body"))
        #expect(!query.contains { $0.name == "$expand" })
    }

    @Test func oldCursorWithInvalidSelectionRestartsWithoutDeletingLocalData() async throws {
        let fixture = HTTPFixture([
            .init(status: 400, body: #"{"error":{"code":"RequestBroker--ParseUri","message":"Could not find a property named 'meetingMessageType' on type 'Microsoft.OutlookServices.Message'."}}"#),
            .init(body: completedPage),
        ])
        let graph = try fixture.graph()
        let store = try MailStore.inMemory()
        var message = StoredMessage(message: try GraphClient.decoder.decode(Message.self, from: Data(HTTPFixture.message("saved").utf8)), folder: "inbox")
        message.localFolder = "Projetos"; message.isRead = true
        try store.upsert([message])
        let old = URL(string: "https://graph.microsoft.com/v1.0/old?$deltatoken=opaque")!
        try store.setDeltaLink(old, for: "inbox")
        try await MailSync(graph: graph, store: store).sync(folder: "inbox")
        #expect(fixture.requests.first?.url == old)
        #expect(fixture.requests.last?.url?.path == "/v1.0/me/mailFolders/inbox/messages/delta")
        #expect(try store.message(id: "saved") == message)
        #expect(await graph.isSignedIn)
        #expect(try store.isFullyIndexed(folder: "inbox"))
    }

    @Test func expiredCursorRestartsOnce() async throws {
        let fixture = HTTPFixture([.init(status: 410), .init(body: completedPage)])
        let store = try MailStore.inMemory()
        try store.setDeltaLink(URL(string: "https://graph.microsoft.com/v1.0/old?$deltatoken=expired")!, for: "inbox")
        try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
        #expect(fixture.requests.count == 2)
    }

    @Test func unrelatedBadRequestDoesNotDiscardCursor() async throws {
        let fixture = HTTPFixture([.init(status: 400, body: #"{"error":{"code":"InvalidRequest"}}"#)])
        let store = try MailStore.inMemory()
        let old = URL(string: "https://graph.microsoft.com/v1.0/old?$deltatoken=valid")!
        try store.setDeltaLink(old, for: "inbox")
        do {
            try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
            Issue.record("A falha deveria ser informada")
        } catch let error as GraphError {
            guard case .http(status: 400, body: _) = error else { throw error }
        }
        #expect(try store.deltaLink(for: "inbox") == old)
        #expect(fixture.requests.count == 1)
    }

    @Test func invalidFreshQueryDoesNotRetryForever() async throws {
        let bad = HTTPFixture.Reply(status: 400, body: #"{"error":{"message":"meetingMessageType"}}"#)
        let fixture = HTTPFixture([bad, bad])
        let store = try MailStore.inMemory()
        try store.setDeltaLink(URL(string: "https://graph.microsoft.com/v1.0/old?$deltatoken=opaque")!, for: "inbox")
        do {
            try await MailSync(graph: fixture.graph(), store: store).sync(folder: "inbox")
            Issue.record("A falha deveria ser informada")
        } catch let error as GraphError {
            guard case .http(status: 400, body: _) = error else { throw error }
        }
        #expect(fixture.requests.count == 2)
        #expect(try store.deltaLink(for: "inbox") == nil)
    }
}
