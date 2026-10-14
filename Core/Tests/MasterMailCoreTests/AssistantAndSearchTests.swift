import Foundation
@testable import MasterMailCore
import Testing

struct AssistantAndSearchTests {
    @Test func parsesSearchOperators() {
        let q = SearchQuery.parse("proposta from:marina has:anexo after:2026-01-01 in:Obras_2026 orcamento")
        #expect(q.text == "proposta orcamento")
        #expect(q.from == "marina")
        #expect(q.hasAttachment)
        #expect(q.localFolder == "Obras 2026")
        #expect(Calendar.current.component(.year, from: q.after!) == 2026)
        #expect(SearchQuery.parse("   ").isEmpty)
        #expect(!SearchQuery.parse("from:x").isEmpty)
    }

    @Test func quotedOperatorsKeepNamesWithSpaces() {
        let q = SearchQuery.parse(#"orcamento from:"Ana Silva" in:"Obras 2026""#)
        #expect(q.text == "orcamento")
        #expect(q.from == "Ana Silva")
        #expect(q.localFolder == "Obras 2026")
        #expect(q.hasOperators)
        #expect(SearchQuery.parse("has:apple").text == "has:apple")
        #expect(SearchQuery.parse("before:invalido").text == "before:invalido")
    }

    @Test func searchWithOperatorsFiltersIndex() throws {
        let store = try MailStore.inMemory()
        func m(_ id: String, from: String, subject: String, attach: Bool, daysAgo: Int) -> StoredMessage {
            let json = """
            {"id":"\(id)","subject":"\(subject)","from":{"emailAddress":{"name":"\(from)","address":"\(from)@bdil.com.br"}},"isRead":true,"hasAttachments":\(attach),
             "receivedDateTime":"\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(-daysAgo) * 86400)))"}
            """
            return StoredMessage(message: try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: "inbox")
        }
        try store.upsert([m("1", from: "marina", subject: "Orçamento", attach: true, daysAgo: 1), m("2", from: "carlos", subject: "Orçamento revisado", attach: false, daysAgo: 40)])
        #expect(try store.search(SearchQuery.parse("orcamento from:marina")).map(\.id) == ["1"])
        #expect(try store.search(SearchQuery.parse("has:anexo")).map(\.id) == ["1"])
        #expect(try store.search(SearchQuery.parse("org:bdil")).map(\.id) == ["1", "2"])
        let afterQ = SearchQuery.parse("orcamento after:" + Assistant.dayFormatter.string(from: Date().addingTimeInterval(-10 * 86400)))
        #expect(try store.search(afterQ).map(\.id) == ["1"])
    }

    @Test func assistantParsesActionsAndFallsBack() throws {
        let search = try Assistant.parse(#"Claro! {"kind":"search","query":"proposta loja","from":"marina","after":"2026-08-01","before":null,"say":"Procurando"}"#)
        #expect(search.action == .search(query: "proposta loja", from: "marina", after: Assistant.dayFormatter.date(from: "2026-08-01"), before: nil))
        #expect(try Assistant.parse(#"{"kind":"move","folder":"Obras","say":"Movo?"}"#).action == .move(folder: "Obras"))
        #expect(try Assistant.parse(#"{"kind":"summary","say":"ok"}"#).action == .summary)
        let plain = try Assistant.parse("Não entendi o pedido.")
        #expect(plain.action == .answer && plain.say == "Não entendi o pedido.")
    }
}
