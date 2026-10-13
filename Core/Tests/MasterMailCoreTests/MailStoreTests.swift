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
