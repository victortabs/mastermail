import Foundation

/// Uma Mensagem posicionada na Conversa (ver CONTEXT.md): quem é a mãe, a profundidade e se abre um Ramo.
public struct ConversationNode: Identifiable, Sendable, Hashable {
    public var message: StoredMessage
    public var parentID: String?
    public var depth: Int
    /// A mensagem-mãe tem mais de uma resposta: esta é uma bifurcação.
    public var isBranch: Bool

    public var id: String { message.id }
}

/// Monta a árvore de respostas a partir do `conversationIndex` do Outlook.
/// Formato: 22 bytes de cabeçalho (raiz) + 5 bytes por nível de resposta. A mãe é o índice sem os 5 últimos bytes.
public enum ConversationTree {
    public static func build(_ messages: [StoredMessage]) -> [ConversationNode] {
        let byIndex = Dictionary(messages.compactMap { m in indexBytes(m.conversationIndex).map { ($0, m.id) } }, uniquingKeysWith: { a, _ in a })
        var parentOf: [String: String] = [:]
        for m in messages {
            guard let bytes = indexBytes(m.conversationIndex), bytes.count > 22 else { continue }
            // Sobe de 5 em 5 bytes até achar uma mãe presente (a mãe direta pode não estar na caixa).
            var prefix = bytes.dropLast(5)
            while prefix.count >= 22 {
                if let parent = byIndex[Data(prefix)], parent != m.id { parentOf[m.id] = parent; break }
                prefix = prefix.dropLast(5)
            }
        }
        var childCount: [String: Int] = [:]
        for parent in parentOf.values { childCount[parent, default: 0] += 1 }

        func depth(_ id: String) -> Int {
            var d = 0
            var cur = id
            while let p = parentOf[cur], d < 32 { d += 1; cur = p }
            return d
        }
        return messages.sorted { $0.receivedAt < $1.receivedAt }.map { m in
            let parent = parentOf[m.id]
            return ConversationNode(message: m, parentID: parent, depth: depth(m.id), isBranch: parent.map { childCount[$0, default: 0] > 1 } ?? false)
        }
    }

    static func indexBytes(_ base64: String?) -> Data? {
        guard let base64, let data = Data(base64Encoded: base64), data.count >= 22 else { return nil }
        return data
    }
}
