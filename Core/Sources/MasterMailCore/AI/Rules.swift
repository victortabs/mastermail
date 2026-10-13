import Foundation
import GRDB

/// Regra (CONTEXT.md): condição determinística derivada de uma Explicação. Resolve sem chamar modelo.
public struct Rule: Codable, Sendable, Identifiable, Equatable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "rule"

    public enum Field: String, Codable, Sendable, CaseIterable {
        case sender, domain, subjectContains
    }

    public var id: Int64?
    public var field: Field
    /// Sempre em minúsculas.
    public var value: String
    public var tipo: String?
    public var categoria: String?
    public var pastaLocal: String?
    /// Aplicar sem perguntar (promovida pelo usuário).
    public var automatic: Bool
    /// A Explicação original do usuário.
    public var explanation: String?
    public var hits: Int
    public var createdAt: Date

    public init(id: Int64? = nil, field: Field, value: String, tipo: Tipo? = nil, categoria: String? = nil,
                pastaLocal: String? = nil, automatic: Bool = false, explanation: String? = nil, hits: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.field = field
        self.value = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.tipo = tipo?.rawValue
        self.categoria = categoria
        self.pastaLocal = pastaLocal
        self.automatic = automatic
        self.explanation = explanation
        self.hits = hits
        self.createdAt = createdAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }

    public func matches(_ m: StoredMessage) -> Bool {
        switch field {
        case .sender: m.fromAddress.lowercased() == value
        case .domain: m.fromAddress.lowercased().hasSuffix("@" + value)
        case .subjectContains: m.subject.lowercased().contains(value)
        }
    }
}

public enum RulesEngine {
    /// Primeira Regra que casa, por especificidade: remetente exato > domínio > assunto contém.
    public static func match(_ m: StoredMessage, rules: [Rule]) -> Rule? {
        for field in Rule.Field.allCases {
            if let r = rules.first(where: { $0.field == field && $0.matches(m) }) { return r }
        }
        return nil
    }
}

public enum RuleBuilder {
    private struct Raw: Decodable { var field: String?; var value: String?; var tipo: String?; var categoria: String? }

    /// Transforma a Explicação do usuário em Regra. Com modelo, pede o JSON; sem modelo (ou se ele falhar),
    /// usa o domínio do remetente e o Tipo atual da mensagem.
    public static func fromExplanation(_ text: String, message m: StoredMessage, provider: AIProvider?) async -> Rule {
        let tipoAtual = m.tipo.flatMap(Tipo.init(rawValue:))
        if let provider {
            let user = "Explicação: \(text)\nRemetente: \(m.fromAddress)\nAssunto: \(m.subject)\nTipo atual: \(m.tipo ?? "desconhecido")"
            if let out = try? await provider.complete(system: Prompts.rule, user: user, maxTokens: 120),
               let json = Classifier.extractJSON(out),
               let raw = try? JSONDecoder().decode(Raw.self, from: Data(json.utf8)),
               let field = raw.field.flatMap(Rule.Field.init(rawValue:)),
               let value = raw.value, !value.isEmpty {
                let categoria = raw.categoria.flatMap { $0.lowercased() == "null" || $0.isEmpty ? nil : $0 }
                return Rule(field: field, value: value, tipo: raw.tipo.flatMap(Tipo.init(lenient:)) ?? tipoAtual,
                            categoria: categoria, explanation: text)
            }
        }
        // ponytail: sem modelo, a heurística é "domínio do remetente → Tipo atual"; refinar quando houver correções reais.
        let domain = m.fromAddress.split(separator: "@").last.map(String.init) ?? ""
        return domain.isEmpty
            ? Rule(field: .sender, value: m.fromAddress, tipo: tipoAtual, explanation: text)
            : Rule(field: .domain, value: domain, tipo: tipoAtual, explanation: text)
    }
}
