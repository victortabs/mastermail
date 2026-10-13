import Foundation

/// Monta o prompt compacto de uma Mensagem e lê o JSON que o modelo devolve.
public struct Classifier: Sendable {
    public let provider: AIProvider

    public init(provider: AIProvider) { self.provider = provider }

    public func classify(_ m: StoredMessage) async throws -> Classification {
        let raw = try await provider.complete(system: Prompts.classify, user: Self.prompt(for: m), maxTokens: 200)
        return try Self.parse(raw)
    }

    static func prompt(for m: StoredMessage) -> String {
        let recipients = m.recipients.isEmpty ? 0 : m.recipients.components(separatedBy: ", ").count
        let body = m.bodyText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).prefix(600)
        return """
        De: \(m.fromName) <\(m.fromAddress)>
        Assunto: \(m.subject)
        Destinatários: \(recipients)\(m.hasAttachments ? " · com anexo" : "")
        Texto: \(body)
        """
    }

    private struct Raw: Decodable {
        var tipo: String
        var importante: Bool?
        var justificativa: String?
        var categoria: String?
    }

    /// Extrai do primeiro `{` até o último `}` (modelos envolvem o JSON em prosa ou ```json).
    static func extractJSON(_ text: String) -> String? {
        guard let open = text.firstIndex(of: "{"), let close = text.lastIndex(of: "}"), open < close else { return nil }
        return String(text[open...close])
    }

    static func parse(_ text: String) throws -> Classification {
        guard let json = extractJSON(text) else { throw AIError.badResponse(text) }
        let raw: Raw
        do { raw = try JSONDecoder().decode(Raw.self, from: Data(json.utf8)) } catch { throw AIError.badResponse(text) }
        guard let tipo = Tipo(lenient: raw.tipo) else { throw AIError.badResponse("tipo desconhecido: \(raw.tipo)") }
        let categoria = raw.categoria?.trimmingCharacters(in: .whitespaces)
        let semCategoria = (categoria?.isEmpty ?? true) || categoria?.lowercased() == "null"
        return Classification(tipo: tipo, importante: raw.importante ?? false,
                              justificativa: raw.justificativa ?? "", categoria: semCategoria ? nil : categoria)
    }
}
