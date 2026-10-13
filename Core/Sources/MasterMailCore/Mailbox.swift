import Foundation

/// Operações de caixa postal sobre o GraphClient que não passam pelo Índice local.
public extension GraphClient {
    func me() async throws -> User {
        try await get("me")
    }

    func markRead(id: String, _ isRead: Bool = true) async throws {
        try await patch("me/messages/\(id)", json: Data(#"{"isRead": \#(isRead)}"#.utf8))
    }
}
