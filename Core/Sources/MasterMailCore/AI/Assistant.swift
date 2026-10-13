import Foundation

/// O que a Aba lateral decidiu fazer. Ações só acontecem depois que o usuário aceita (Sugestão, CONTEXT.md).
public enum AssistantAction: Sendable, Equatable {
    case search(query: String, from: String?, after: Date?, before: Date?)
    case move(folder: String)
    case summary
    case draft
    case answer
}

public struct AssistantReply: Sendable, Equatable {
    public var action: AssistantAction
    public var say: String
}

/// Aba lateral (CONTEXT.md): interpreta o pedido, resume e rascunha. Usa o provedor da cadeia da ADR 0004.
public struct Assistant: Sendable {
    public let provider: AIProvider

    public init(provider: AIProvider) { self.provider = provider }

    public func interpret(_ request: String, contextDescription: String) async throws -> AssistantReply {
        let system = Prompts.assistant
            .replacingOccurrences(of: "{today}", with: Self.dayFormatter.string(from: Date()))
            .replacingOccurrences(of: "{context}", with: contextDescription)
        let raw = try await provider.complete(system: system, user: request, maxTokens: 300)
        return try Self.parse(raw)
    }

    /// Resumo de Conversa com janela curta (modelo local ~4k): resume cada mensagem longa antes de juntar.
    public func summarize(_ messages: [StoredMessage]) async throws -> String {
        let pieces = messages.map { m in
            "De: \(m.fromName.isEmpty ? m.fromAddress : m.fromName) em \(Self.dayFormatter.string(from: m.receivedAt))\n\(String(m.bodyText.prefix(1500)))"
        }
        var text = pieces.joined(separator: "\n---\n")
        if text.count > 6000 {
            // ponytail: map-reduce simples; mensagens de 1500 chars em lotes de 4.
            var partials: [String] = []
            for chunk in pieces.chunked(4) {
                partials.append(try await provider.complete(system: Prompts.summarize, user: chunk.joined(separator: "\n---\n"), maxTokens: 300))
            }
            text = partials.joined(separator: "\n")
        }
        return try await provider.complete(system: Prompts.summarize, user: text, maxTokens: 400).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func draft(instruction: String, conversation: [StoredMessage], me: String) async throws -> String {
        let history = conversation.suffix(4).map { m in
            "\(m.fromAddress.lowercased() == me.lowercased() ? "EU" : (m.fromName.isEmpty ? m.fromAddress : m.fromName)): \(String(m.bodyText.prefix(1200)))"
        }.joined(separator: "\n---\n")
        let user = "Instrução: \(instruction.isEmpty ? "responda" : instruction)\n\nConversa:\n\(history)"
        return try await provider.complete(system: Prompts.draft, user: user, maxTokens: 500).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func parse(_ raw: String) throws -> AssistantReply {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"), start < end,
              let obj = try? JSONSerialization.jsonObject(with: Data(raw[start...end].utf8)) as? [String: Any] else {
            // Sem JSON: trata como resposta direta.
            return AssistantReply(action: .answer, say: raw.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let say = (obj["say"] as? String) ?? ""
        func str(_ k: String) -> String? { let v = obj[k] as? String; return (v?.isEmpty == false && v != "null") ? v : nil }
        switch obj["kind"] as? String {
        case "search":
            return AssistantReply(action: .search(query: str("query") ?? "", from: str("from"), after: str("after").flatMap(dayFormatter.date), before: str("before").flatMap(dayFormatter.date)), say: say)
        case "move": return AssistantReply(action: .move(folder: str("folder") ?? ""), say: say)
        case "summary": return AssistantReply(action: .summary, say: say)
        case "draft": return AssistantReply(action: .draft, say: say)
        default: return AssistantReply(action: .answer, say: say.isEmpty ? raw : say)
        }
    }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

extension Array {
    func chunked(_ size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
