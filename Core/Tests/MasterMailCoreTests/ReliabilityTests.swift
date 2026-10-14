import Foundation
@testable import MasterMailCore
import Testing

struct ReliabilityTests {
    @Test func overlappingDrainsNeverRepeatAnAction() async throws {
        let fixture = HTTPFixture([.init(delay: .milliseconds(60)), .init()])
        let graph = try fixture.graph()
        let queue = ActionQueue(fileURL: fixture.directory.appendingPathComponent("queue.json"))
        try await queue.enqueue(.markRead(id: "1", isRead: true))
        try await queue.enqueue(.flag(id: "2", flagged: true))
        async let first = queue.drain(using: graph)
        async let second = queue.drain(using: graph)
        let total = await first + second
        #expect(total == 2)
        #expect(await queue.count == 0)
        #expect(fixture.requests.count == 2)
        #expect(await ActionQueue(fileURL: await queue.fileURL).count == 0)
    }

    @Test(arguments: [401, 403, 408, 429, 500])
    func failedActionsSurviveARestart(status: Int) async throws {
        let fixture = HTTPFixture([.init(status: status)])
        let queue = ActionQueue(fileURL: fixture.directory.appendingPathComponent("queue.json"))
        let action = PendingAction.localFolder(id: "1", name: "Obras")
        try await queue.enqueue(action)
        #expect(await queue.drain(using: try fixture.graph()) == 0)
        #expect(await queue.lastError != nil)
        let reopened = ActionQueue(fileURL: await queue.fileURL)
        #expect(await reopened.pendingActions == [action])
    }

    @Test func refreshIsSharedAcrossConcurrentRequests() async throws {
        let fixture = HTTPFixture([
            .init(body: #"{"access_token":"renewed","refresh_token":"r","expires_in":3600}"#, delay: .milliseconds(60)),
            .init(body: #"{"mail":"person@example.test"}"#), .init(body: #"{"mail":"person@example.test"}"#),
        ])
        let graph = try fixture.graph(expired: true)
        async let first = graph.me()
        async let second = graph.me()
        _ = try await (first, second)
        #expect(fixture.requests.filter { $0.url?.path.contains("token") == true }.count == 1)
        #expect(fixture.requests.filter { $0.value(forHTTPHeaderField: "Authorization") == "Bearer renewed" }.count == 2)
    }

    @Test func signOutDuringRefreshDoesNotReconnect() async throws {
        let fixture = HTTPFixture([.init(body: #"{"access_token":"renewed","expires_in":3600}"#, delay: .milliseconds(150))])
        let graph = try fixture.graph(expired: true)
        let request = Task { try await graph.me() }
        while fixture.requests.isEmpty { await Task.yield() }
        await graph.signOut()
        _ = try? await request.value
        #expect(await graph.isSignedIn == false)
    }

    @Test func throttlingRespectsRetryAfterWithoutHammeringTheServer() async throws {
        let fixture = HTTPFixture([.init(status: 429, headers: ["Retry-After": "120"])])
        let graph = try fixture.graph()
        _ = try? await graph.me()
        _ = try? await graph.me()
        #expect(fixture.requests.count == 1)
    }

    @Test func deltaCannotOverwritePendingLocalActions() throws {
        let store = try MailStore.inMemory()
        let message = try GraphClient.decoder.decode(Message.self, from: Data(HTTPFixture.message("1").utf8))
        let initial = StoredMessage(message: message, folder: "inbox")
        try store.upsert([initial])
        try store.upsert([initial], preserving: [.markRead(id: "1", isRead: true), .flag(id: "1", flagged: true), .localFolder(id: "1", name: "Obras"), .categories(id: "1", categories: ["Cliente"])])
        let saved = try #require(try store.message(id: "1"))
        #expect(saved.isRead && saved.isFlagged)
        #expect(saved.localFolder == "Obras")
        #expect(saved.categories == ["Cliente"])
        try store.applyLocalFolders(["1": "Servidor"], preserving: ["1"])
        #expect(try store.message(id: "1")?.localFolder == "Obras")
        try store.applyLocalFolders([:])
        #expect(try store.message(id: "1")?.localFolder == nil)
    }

    @Test func bodyDownloadDoesNotOverwriteReadOrFlagState() throws {
        let store = try MailStore.inMemory()
        let message = try GraphClient.decoder.decode(Message.self, from: Data(HTTPFixture.message("1").utf8))
        try store.upsert([StoredMessage(message: message, folder: "inbox")])
        try store.setRead(id: "1", true)
        try store.setFlagged(id: "1", true)
        try store.cacheBody(id: "1", html: "<p>Corpo</p>")
        let saved = try #require(try store.message(id: "1"))
        #expect(saved.isRead && saved.isFlagged && saved.bodyHTML == "<p>Corpo</p>")
    }

    @Test func movedMessageKeepsLocalMetadataAndSearchIndex() throws {
        let store = try MailStore.inMemory()
        let message = try GraphClient.decoder.decode(Message.self, from: Data(HTTPFixture.message("1").utf8))
        var stored = StoredMessage(message: message, folder: "inbox")
        stored.tipo = Tipo.financeiro.rawValue
        stored.localFolder = "Contas"
        stored.snoozedUntil = .distantFuture
        try store.upsert([stored])
        stored.id = "new-id"; stored.folder = "archive"
        try store.replace(id: "1", with: stored)
        #expect(try store.message(id: "1") == nil)
        #expect(try store.message(id: "new-id") == stored)
        #expect(try store.search("Teste").map(\.id) == ["new-id"])
    }

    @Test func remoteImagesRequireExplicitConsentInInitialHTML() {
        let html = #"<img src="https://example.test/tracker"><script>alert(1)</script>"#
        let blocked = HTMLText.document(html)
        #expect(blocked.contains("img-src data: cid:;"))
        #expect(blocked.contains("default-src 'none'"))
        #expect(HTMLText.document(html, allowRemoteImages: true).contains("img-src data: cid: https: http:;"))
    }
    @Test func folderDiscoveryFollowsNestedFoldersAndPagination() async throws {
        func folder(_ id: String, children: Int) -> String {
            #"{"id":"\#(id)","displayName":"\#(id)","childFolderCount":\#(children),"unreadItemCount":0,"totalItemCount":1}"#
        }
        let fixture = HTTPFixture([
            .init(body: "{\"value\":[" + folder("root", children: 1) + "]}"),
            .init(body: "{\"value\":[" + folder("child", children: 1) + "],\"@odata.nextLink\":\"https://graph.microsoft.com/v1.0/next-page\"}"),
            .init(body: "{\"value\":[" + folder("sibling", children: 0) + "]}"),
            .init(body: "{\"value\":[" + folder("grandchild", children: 0) + "]}"),
        ])
        let folders = try await fixture.graph().folders()
        #expect(folders.map(\.id) == ["root", "child", "sibling", "grandchild"])
        #expect(folders.map(\.depth) == [0, 1, 1, 2])
        #expect(fixture.requests.count == 4)
    }

    @Test func reconnectingAnotherAccountCannotReuseTheIndex() throws {
        let store = try MailStore.inMemory()
        try store.claimAccount(identifier: "account-1", displayName: "first@example.test")
        try store.claimAccount(identifier: "account-1", displayName: "renamed@example.test")
        #expect(throws: MailStore.AccountMismatch.self) {
            try store.claimAccount(identifier: "account-2", displayName: "second@example.test")
        }
        try store.claimAccount(identifier: "account-1", displayName: "first@example.test")
    }

}
