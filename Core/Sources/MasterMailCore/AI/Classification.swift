import Foundation

/// Tipo (CONTEXT.md): a classe que a IA atribui a toda mensagem. Define se é Ruído.
public enum Tipo: String, Codable, CaseIterable, Sendable {
    case pessoa, newsletter, notificacao, promocao, financeiro, convite

    /// Ruído = tudo que não é Pessoa nem Convite.
    public var isRuido: Bool { self != .pessoa && self != .convite }

    public var label: String {
        switch self {
        case .pessoa: "Pessoa"
        case .newsletter: "Newsletter"
        case .notificacao: "Notificação automática"
        case .promocao: "Promoção"
        case .financeiro: "Financeiro"
        case .convite: "Convite"
        }
    }

    static let ruido = allCases.filter(\.isRuido).map(\.rawValue)

    /// Aceita "Notificação", "PROMOÇÃO", "notificacao automatica"... (modelos ignoram o esquema às vezes).
    public init?(lenient raw: String) {
        let folded = raw.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let t = Tipo.allCases.first(where: { folded.hasPrefix($0.rawValue) }) else { return nil }
        self = t
    }
}

/// O resultado da classificação de uma Mensagem: Tipo, Importante, Justificativa e Categoria sugerida.
public struct Classification: Codable, Sendable, Equatable {
    public var tipo: Tipo
    public var importante: Bool
    public var justificativa: String
    public var categoria: String?

    public init(tipo: Tipo, importante: Bool = false, justificativa: String, categoria: String? = nil) {
        self.tipo = tipo
        self.importante = importante
        self.justificativa = justificativa
        self.categoria = categoria
    }
}
