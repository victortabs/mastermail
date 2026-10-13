import Foundation

/// Campos que o app grava num rascunho do servidor.
public struct DraftPatch: Encodable, Sendable {
    public var subject: String?
    public var toRecipients: [Recipient]?
    public var ccRecipients: [Recipient]?
    public var body: ItemBody?

    public init(subject: String? = nil, toRecipients: [Recipient]? = nil, ccRecipients: [Recipient]? = nil, body: ItemBody? = nil) {
        self.subject = subject
        self.toRecipients = toRecipients
        self.ccRecipients = ccRecipients
        self.body = body
    }
}

/// Composição: rascunhos vivem no servidor (requisito), o Graph monta a citação do histórico.
public extension GraphClient {
    /// Responder (= a todos, ver CONTEXT.md) ou Responder ao remetente. Devolve o rascunho com citação e destinatários.
    func createReply(to messageID: String, all: Bool) async throws -> Message {
        try await postDecoding("me/messages/\(messageID)/\(all ? "createReplyAll" : "createReply")", json: Data("{}".utf8))
    }

    func createForward(of messageID: String) async throws -> Message {
        try await postDecoding("me/messages/\(messageID)/createForward", json: Data("{}".utf8))
    }

    func createDraft() async throws -> Message {
        try await postDecoding("me/messages", json: Data("{}".utf8))
    }

    func updateDraft(id: String, _ patch: DraftPatch) async throws {
        try await self.patch("me/messages/\(id)", json: JSONEncoder().encode(patch))
    }

    func send(draftID: String) async throws {
        try await post("me/messages/\(draftID)/send", json: Data())
    }

    func deleteDraft(id: String) async throws {
        try await delete("me/messages/\(id)")
    }
}

/// Monta um Recipient a partir de "Nome <a@b>" ou "a@b".
public extension Recipient {
    init(parsing text: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        if let open = t.lastIndex(of: "<"), t.hasSuffix(">") {
            let name = t[..<open].trimmingCharacters(in: .whitespaces)
            let address = t[t.index(after: open)..<t.index(before: t.endIndex)].trimmingCharacters(in: .whitespaces)
            self.init(emailAddress: EmailAddress(name: name.isEmpty ? nil : name, address: address))
        } else {
            self.init(emailAddress: EmailAddress(name: nil, address: t))
        }
    }

    static func parseList(_ text: String) -> [Recipient] {
        text.split(whereSeparator: { $0 == "," || $0 == ";" }).map { Recipient(parsing: String($0)) }.filter { !($0.emailAddress.address ?? "").isEmpty }
    }

    var display: String {
        let address = emailAddress.address ?? ""
        if let name = emailAddress.name, !name.isEmpty, name != address { return "\(name) <\(address)>" }
        return address
    }
}
