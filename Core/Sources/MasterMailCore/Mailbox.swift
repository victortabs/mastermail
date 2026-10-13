import Foundation

/// Operações de caixa postal sobre o GraphClient.
public extension GraphClient {
    func me() async throws -> User {
        try await get("me")
    }

    /// Mensagens da Caixa de Entrada do servidor, mais recentes primeiro.
    func inbox(top: Int = 50) async throws -> [Message] {
        let page: GraphPage<Message> = try await get("me/mailFolders/inbox/messages", query: [
            .init(name: "$top", value: String(top)),
            .init(name: "$select", value: Message.listFields),
            .init(name: "$orderby", value: "receivedDateTime desc"),
        ])
        return page.value
    }

    /// A mensagem com o corpo completo.
    func message(id: String) async throws -> Message {
        try await get("me/messages/\(id)", query: [
            .init(name: "$select", value: Message.listFields + ",body"),
        ])
    }

    func markRead(id: String, _ isRead: Bool = true) async throws {
        try await patch("me/messages/\(id)", json: Data(#"{"isRead": \#(isRead)}"#.utf8))
    }
}
