import Foundation

/// Nomes bem conhecidos que o Graph aceita no lugar do id.
public enum WellKnownFolder: String, CaseIterable, Sendable {
    case inbox, sentitems, drafts, archive, deleteditems, junkemail
}

/// Operações de caixa postal sobre o GraphClient que não passam pelo Índice local.
public extension GraphClient {
    func me() async throws -> User {
        try await get("me")
    }

    /// Todas as pastas (raiz + um nível de subpastas), já com `depth`.
    func folders() async throws -> [MailFolder] {
        let top: GraphPage<MailFolder> = try await get("me/mailFolders", query: [.init(name: "$top", value: "200")])
        var all: [MailFolder] = []
        for folder in top.value {
            all.append(folder)
            if folder.childFolderCount > 0 {
                let children: GraphPage<MailFolder> = try await get("me/mailFolders/\(folder.id)/childFolders", query: [.init(name: "$top", value: "200")])
                all += children.value.map { var c = $0; c.depth = 1; return c }
            }
        }
        return all
    }

    /// Id real de cada pasta bem conhecida (o v1.0 não devolve `wellKnownName` na listagem).
    func wellKnownFolderIDs() async throws -> [WellKnownFolder: String] {
        var map: [WellKnownFolder: String] = [:]
        for name in WellKnownFolder.allCases {
            if let folder: MailFolder = try? await get("me/mailFolders/\(name.rawValue)", query: [.init(name: "$select", value: "id,displayName,childFolderCount,unreadItemCount,totalItemCount")]) {
                map[name] = folder.id
            }
        }
        return map
    }

    /// Corpo HTML de uma mensagem antiga (fora da retenção do Índice local).
    func bodyHTML(id: String) async throws -> String? {
        let m: Message = try await get("me/messages/\(id)", query: [.init(name: "$select", value: "body")])
        return m.body?.contentType.lowercased() == "html" ? m.body?.content : nil
    }

    /// Anexos inline (imagens de assinatura etc.), com bytes.
    func inlineAttachments(messageID: String) async throws -> [Attachment] {
        let page: GraphPage<Attachment> = try await get("me/messages/\(messageID)/attachments", query: [
            .init(name: "$filter", value: "isInline eq true"),
        ])
        return page.value
    }

    func markRead(id: String, _ isRead: Bool = true) async throws {
        try await patch("me/messages/\(id)", json: Data(#"{"isRead": \#(isRead)}"#.utf8))
    }

    /// Todas as mensagens que têm Pasta local gravada no servidor (ADR 0006): [id: nome]. Reconcilia o índice no login.
    func localFolderAssignments() async throws -> [String: String] {
        var result: [String: String] = [:]
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("me/messages"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "$top", value: "500"),
            .init(name: "$select", value: "id"),
            .init(name: "$filter", value: "singleValueExtendedProperties/any(ep:ep/id eq '\(ExtendedProperty.localFolderID)' and ep/value ne null)"),
            .init(name: "$expand", value: ExtendedProperty.expand),
        ]
        var url: URL? = components.url
        while let next = url {
            let page: GraphPage<Message> = try await get(url: next)
            for m in page.value { if let name = m.localFolder { result[m.id] = name } }
            url = page.nextLink
        }
        return result
    }

    /// Grava (ou limpa, com nil) a Pasta local na própria mensagem (ADR 0006).
    func setLocalFolder(id: String, _ name: String?) async throws {
        let patch = ["singleValueExtendedProperties": [ExtendedProperty(id: ExtendedProperty.localFolderID, value: name ?? "")]]
        try await self.patch("me/messages/\(id)", json: JSONEncoder().encode(patch))
    }

    func setFlag(id: String, _ flagged: Bool) async throws {
        try await patch("me/messages/\(id)", json: Data(#"{"flag": {"flagStatus": "\#(flagged ? "flagged" : "notFlagged")"}}"#.utf8))
    }

    /// Move para uma pasta do servidor (arquivar = archive, apagar = deleteditems). Devolve a cópia nova: o id muda ao mover.
    @discardableResult
    func move(id: String, to destination: WellKnownFolder) async throws -> Message {
        try await move(id: id, destinationID: destination.rawValue)
    }

    @discardableResult
    func move(id: String, destinationID: String) async throws -> Message {
        try await postDecoding("me/messages/\(id)/move", json: Data(#"{"destinationId": "\#(destinationID)"}"#.utf8))
    }
}
