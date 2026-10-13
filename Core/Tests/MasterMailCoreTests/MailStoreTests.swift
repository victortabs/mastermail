import Foundation
@testable import MasterMailCore
import Testing

struct MailStoreTests {
    private func sample(id: String, subject: String, from: String, body: String, daysAgo: Double = 0) -> StoredMessage {
        let json = """
        {"id":"\(id)","subject":"\(subject)","from":{"emailAddress":{"name":"\(from)","address":"\(from.lowercased())@bdil.com.br"}},
         "receivedDateTime":"\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(-daysAgo * 86400)))",
         "isRead":false,"hasAttachments":false,"body":{"contentType":"html","content":"\(body)"}}
        """
        let message = try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8))
        return StoredMessage(message: message, folder: "inbox")
    }

    @Test func searchFindsBySubjectBodyAndSenderWithoutDiacritics() throws {
        let store = try MailStore.inMemory()
        try store.upsert([
            sample(id: "1", subject: "Orçamento loja Oscar Freire", from: "Marina", body: "<p>Segue a <b>proposta</b> revisada.</p>"),
            sample(id: "2", subject: "Reunião de obra", from: "Carlos", body: "<p>Cronograma da semana</p>", daysAgo: 1),
        ])
        #expect(try store.search("orcamento").map(\.id) == ["1"])
        #expect(try store.search("proposta revis").map(\.id) == ["1"])
        #expect(try store.search("carlos").map(\.id) == ["2"])
        #expect(try store.search("inexistente").isEmpty)
        #expect(try store.messages(in: "inbox").map(\.id) == ["1", "2"])
    }

    @Test func upsertReplacesAndDeleteRemoves() throws {
        let store = try MailStore.inMemory()
        try store.upsert([sample(id: "1", subject: "v1", from: "A", body: "x")])
        try store.upsert([sample(id: "1", subject: "v2", from: "A", body: "x")])
        #expect(try store.message(id: "1")?.subject == "v2")
        #expect(try store.count(in: "inbox") == 1)
        try store.delete(ids: ["1"])
        #expect(try store.count(in: "inbox") == 0)
    }

    @Test func htmlBecomesPlainText() {
        let html = "<html><head><style>p{}</style></head><body><p>Ol&aacute;, <b>Victor</b>!</p><p>Segue&nbsp;anexo &amp; link.</p><script>x()</script></body></html>"
        #expect(HTMLText.plainText(from: html) == "Olá, Victor !\nSegue anexo & link.")
    }

    @Test func deltaItemsDecodeRemovedAndChanged() throws {
        let json = """
        {"value":[{"id":"a","@removed":{"reason":"deleted"}},
                  {"id":"b","subject":"s","receivedDateTime":"2026-10-13T12:00:00Z","isRead":true,"hasAttachments":false}],
         "@odata.deltaLink":"https://graph.microsoft.com/v1.0/x?$deltatoken=1"}
        """
        let page = try GraphClient.decoder.decode(DeltaPage<DeltaMessage>.self, from: Data(json.utf8))
        #expect(page.value.map(\.removed) == [true, false])
        #expect(page.value[1].message?.subject == "s")
        #expect(page.deltaLink != nil && page.nextLink == nil)
    }
}

struct InlineImageTests {
    @Test func cidBecomesDataURL() {
        let html = #"<p>Assinatura</p><img src="cid:logo@empresa">"#
        let out = HTMLText.embedInline(html, attachments: [
            Attachment(id: "1", name: "logo.png", contentType: "image/png", contentId: "<logo@empresa>", isInline: true, contentBytes: "AAAA"),
        ])
        #expect(out == #"<p>Assinatura</p><img src="data:image/png;base64,AAAA">"#)
    }
}

struct LocalFolderTests {
    @Test func localFolderComesFromExtendedPropertyAndLeavesInbox() throws {
        let store = try MailStore.inMemory()
        let json = """
        {"id":"1","receivedDateTime":"2026-10-13T12:00:00Z","isRead":true,"hasAttachments":false,
         "singleValueExtendedProperties":[{"id":"\(ExtendedProperty.localFolderID)","value":"Obras"}]}
        """
        let m = StoredMessage(message: try GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: "inbox")
        #expect(m.localFolder == "Obras")
        try store.upsert([m])
        #expect(try store.messages(in: "inbox").isEmpty)
        #expect(try store.messages(localFolder: "Obras").map(\.id) == ["1"])
        try store.createLocalFolder("Vazia")
        #expect(try store.localFolders() == ["Obras", "Vazia"])
        #expect(try store.renameLocalFolder("Obras", to: "Projetos") == ["1"])
        #expect(try store.localFolders() == ["Projetos", "Vazia"])
        try store.setLocalFolder(id: "1", nil)
        #expect(try store.messages(in: "inbox").map(\.id) == ["1"])
    }
}

struct QuoteAndFollowUpTests {
    @Test func outlookQuoteIsCollapsed() {
        let html = "<div>Minha resposta aqui.</div><div id=\"divRplyFwdMsg\"><b>De:</b> Marina</div><div>texto antigo</div>"
        let out = HTMLText.collapseQuotes(html)
        #expect(out.hasPrefix("<div>Minha resposta aqui.</div><details"))
        #expect(out.contains("··· citação"))
        #expect(HTMLText.collapseQuotes("<p>sem citação</p>") == "<p>sem citação</p>")
    }

    private func msg(_ id: String, folder: String, from: String, conv: String, hoursAgo: Double) -> StoredMessage {
        let json = """
        {"id":"\(id)","conversationId":"\(conv)","from":{"emailAddress":{"address":"\(from)"}},"isRead":true,"hasAttachments":false,
         "receivedDateTime":"\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(-hoursAgo * 3600)))"}
        """
        return StoredMessage(message: try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: folder)
    }

    @Test func followUpListsAndSnooze() throws {
        let store = try MailStore.inMemory()
        try store.upsert([
            msg("a1", folder: "sent", from: "me@x.com", conv: "A", hoursAgo: 100),   // eu mandei, ninguém respondeu → sem resposta deles
            msg("b1", folder: "sent", from: "me@x.com", conv: "B", hoursAgo: 100),
            msg("b2", folder: "inbox", from: "ana@y.com", conv: "B", hoursAgo: 5),  // ela respondeu por último → sem resposta sua
            msg("c1", folder: "inbox", from: "bob@z.com", conv: "C", hoursAgo: 5),  // nunca respondi nada nessa → não é pendência
            msg("d1", folder: "sent", from: "me@x.com", conv: "D", hoursAgo: 1),    // recente demais
        ])
        #expect(try store.awaitingTheirReply(sent: "sent", me: "me@x.com").map(\.id) == ["a1", "b1"].filter { $0 == "a1" } + [])
        #expect(try store.awaitingMyReply(inbox: "inbox", me: "me@x.com").map(\.id) == ["b2"])
        try store.setSnooze(id: "c1", until: Date().addingTimeInterval(3600))
        #expect(try store.messages(in: "inbox").map(\.id) == ["b2"])
        #expect(try store.snoozed().map(\.id) == ["c1"])
        try store.setSnooze(id: "c1", until: Date().addingTimeInterval(-1))
        #expect(try store.messages(in: "inbox").map(\.id) == ["b2", "c1"])
    }
}

struct PhishingTests {
    @Test func detectsMismatchedNameAndLink() {
        let signals = HTMLText.phishingSignals(fromName: "Banco Itau <seguranca@itau.com.br>", fromAddress: "x@golpe.ru",
                                               html: #"<a href="https://golpe.ru/login">https://www.itau.com.br/acesso</a>"#)
        #expect(signals.count == 2)
        #expect(HTMLText.phishingSignals(fromName: "Marina", fromAddress: "m@bdil.com.br", html: #"<a href="https://bdil.com.br/x">https://bdil.com.br/x</a>"#).isEmpty)
    }
}

struct ActionQueueTests {
    @Test func queuePersistsAndRoundTrips() async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("q-\(UUID().uuidString).json")
        let q = ActionQueue(fileURL: url)
        await q.enqueue(.markRead(id: "a", isRead: true))
        await q.enqueue(.localFolder(id: "b", name: "Obras"))
        #expect(await q.count == 2)
        let reloaded = ActionQueue(fileURL: url)
        #expect(await reloaded.count == 2)
        #expect(await reloaded.items == [.markRead(id: "a", isRead: true), .localFolder(id: "b", name: "Obras")])
    }
}
