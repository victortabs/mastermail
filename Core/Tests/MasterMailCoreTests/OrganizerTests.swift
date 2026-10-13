import Foundation
@testable import MasterMailCore
import Testing

struct OrganizerTests {
    @Test func parsesPlanAndApplies() throws {
        let raw = """
        Aqui está: {"summary":"ok","rules":[{"field":"domain","value":"Substack.com","tipo":"newsletter","pastaLocal":null,"reason":"boletim"},
        {"field":"domain","value":"bdil.com.br","tipo":"pessoa","pastaLocal":"Bacio di Latte","reason":"cliente"}],
        "folders":[{"name":"Bacio di Latte","description":"obras BDL","domains":["bdil.com.br"]}],"categories":["Obra"]}
        """
        let plan = try Organizer.parse(raw)
        #expect(plan.rules.count == 2 && plan.folders.first?.name == "Bacio di Latte")
        let store = try MailStore.inMemory()
        func m(_ id: String, from: String) -> StoredMessage {
            let json = #"{"id":"\#(id)","from":{"emailAddress":{"address":"\#(from)"}},"isRead":true,"hasAttachments":false,"receivedDateTime":"2026-10-13T12:00:00Z"}"#
            return StoredMessage(message: try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: "inbox")
        }
        try store.upsert([m("1", from: "marina@bdil.com.br"), m("2", from: "news@substack.com")])
        let moved = try store.apply(plan, moveExisting: true)
        #expect(moved.map(\.id) == ["1"])
        #expect(try store.localFolders() == ["Bacio di Latte"])
        #expect(try store.rules().count == 2)
        #expect(try store.rules().first { $0.value == "substack.com" }?.tipo == "newsletter")
    }

    @Test func profileAggregatesByDomain() throws {
        let store = try MailStore.inMemory()
        func m(_ id: String, from: String, folder: String, subject: String, read: Bool = true, to: String = "") -> StoredMessage {
            let json = #"{"id":"\#(id)","subject":"\#(subject)","from":{"emailAddress":{"address":"\#(from)"}},"toRecipients":[{"emailAddress":{"address":"\#(to)"}}],"isRead":\#(read),"hasAttachments":false,"receivedDateTime":"2026-10-13T12:00:00Z"}"#
            return StoredMessage(message: try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: folder)
        }
        try store.upsert([m("1", from: "a@x.com", folder: "inbox", subject: "Oi"), m("2", from: "b@x.com", folder: "inbox", subject: "Tchau", read: false),
                          m("3", from: "me@v.com", folder: "sent", subject: "Re: Oi", to: "a@x.com")])
        let profile = try store.profile(inbox: "inbox", sent: "sent")
        #expect(profile.total == 2 && profile.unread == 1)
        #expect(profile.senders.first?.domain == "x.com" && profile.senders.first?.count == 2 && profile.senders.first?.repliedTo == 1)
        #expect(profile.text.contains("x.com | 2 | 50% | 1"))
    }
}
