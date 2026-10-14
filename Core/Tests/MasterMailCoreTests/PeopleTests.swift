import Foundation
@testable import MasterMailCore
import Testing

struct PeopleTests {
    private func sample(id: String, from: (String, String), to: [(String, String)], daysAgo: Double = 0) -> StoredMessage {
        let recipients = to.map { #"{"emailAddress":{"name":"\#($0.0)","address":"\#($0.1)"}}"# }.joined(separator: ",")
        let json = """
        {"id":"\(id)","subject":"s","from":{"emailAddress":{"name":"\(from.0)","address":"\(from.1)"}},"toRecipients":[\(recipients)],
         "receivedDateTime":"\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(-daysAgo * 86400)))",
         "isRead":false,"hasAttachments":false}
        """
        let message = try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8))
        return StoredMessage(message: message, folder: "inbox")
    }

    private func store() throws -> MailStore {
        let store = try MailStore.inMemory()
        try store.upsert([
            sample(id: "1", from: ("Marina Silva", "marina@bdil.com.br"), to: [("Usuário", "owner@example.test"), ("", "carlos@bdil.com.br")]),
            sample(id: "2", from: ("Usuário", "Owner@example.test"), to: [("Marina Silva", "marina@bdil.com.br"), ("Zé", "ze@gmail.com")], daysAgo: 1),
            sample(id: "3", from: ("Ana", "ana@sephora.com"), to: [("Usuário", "owner@example.test")], daysAgo: 2),
        ])
        try store.refreshPeople(me: "owner@example.test")
        return store
    }

    @Test func recipientsAreParsedAndOwnAddressExcluded() throws {
        let contacts = try store().contacts()
        #expect(Set(contacts.map(\.address)) == ["marina@bdil.com.br", "carlos@bdil.com.br", "ze@gmail.com", "ana@sephora.com"])
        let marina = contacts.first { $0.address == "marina@bdil.com.br" }
        #expect(marina?.messageCount == 2 && marina?.name == "Marina Silva" && marina?.domain == "bdil.com.br")
        #expect(try store().contacts(domain: "bdil.com.br").map(\.address) == ["marina@bdil.com.br", "carlos@bdil.com.br"])
    }

    @Test func publicDomainsFormNoOrganizationAndCountsAreDistinctMessages() throws {
        let orgs = try store().organizations()
        #expect(orgs.map(\.domain) == ["bdil.com.br", "sephora.com"])
        #expect(orgs[0].name == "Bdil" && orgs[0].messageCount == 2 && orgs[0].contactCount == 2)
        #expect(orgs[1].messageCount == 1 && orgs[1].contactCount == 1)
        #expect(try store().messages(domain: "bdil.com.br").map(\.id) == ["1", "2"])
    }

    @Test func renameAndMergeFold() throws {
        let store = try store()
        try store.renameOrganization(domain: "bdil.com.br", name: "Bacio di Latte")
        #expect(try store.organizations().first?.name == "Bacio di Latte")
        try store.mergeOrganization(domain: "sephora.com", into: "bdil.com.br")
        let orgs = try store.organizations()
        #expect(orgs.map(\.domain) == ["bdil.com.br"])
        #expect(orgs[0].messageCount == 3 && orgs[0].contactCount == 3)
        #expect(try store.contacts(domain: "bdil.com.br").count == 3)
        #expect(try store.messages(domain: "bdil.com.br").map(\.id) == ["1", "2", "3"])
        try store.refreshPeople(me: "owner@example.test") // sobrevive ao recálculo
        #expect(try store.organizations().map(\.name) == ["Bacio di Latte"])
    }

    @Test func suggestionsOrderedByFrequencyAndSavedFlag() throws {
        let store = try store()
        try store.markSaved([(name: "Carlos Souza", address: "carlos@bdil.com.br"), (name: "Novo", address: "novo@bdil.com.br")])
        #expect(try store.suggestRecipients(prefix: "m").map(\.address) == ["marina@bdil.com.br"])
        #expect(try store.suggestRecipients(prefix: "silva").map(\.address) == ["marina@bdil.com.br"])
        #expect(try store.suggestRecipients(prefix: "ca").map(\.display) == ["Carlos Souza <carlos@bdil.com.br>"])
        #expect(try store.suggestRecipients(prefix: "bdil").isEmpty)
        #expect(try store.suggestRecipients(prefix: "").isEmpty)
        let contacts = try store.contacts(domain: "bdil.com.br")
        #expect(contacts.map(\.address) == ["marina@bdil.com.br", "carlos@bdil.com.br", "novo@bdil.com.br"])
        #expect(contacts.map(\.isSaved) == [false, true, true])
        #expect(try store.organizations().first?.contactCount == 3)
    }
}
