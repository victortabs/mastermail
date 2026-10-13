import Foundation

/// Operações de caixa postal sobre o GraphClient que não passam pelo Índice local.
public extension GraphClient {
    func me() async throws -> User {
        try await get("me")
    }

    /// Corpo HTML de uma mensagem antiga (fora da retenção do Índice local).
    func bodyHTML(id: String) async throws -> String? {
        let m: Message = try await get("me/messages/\(id)", query: [.init(name: "$select", value: "body")])
        return m.body?.contentType.lowercased() == "html" ? m.body?.content : nil
    }

    func markRead(id: String, _ isRead: Bool = true) async throws {
        try await patch("me/messages/\(id)", json: Data(#"{"isRead": \#(isRead)}"#.utf8))
    }
}
