import Foundation

/// Classifica o que ainda não tem Tipo, na ordem do ADR 0004: Regra → modelo local → nuvem (opt-in) → pula.
public actor ClassificationPipeline {
    public let store: MailStore
    public let settings: AISettingsStore
    private let override: AIProvider?
    public private(set) var lastError: String?

    /// `provider` força um modelo (testes); nil escolhe pelos ajustes.
    public init(store: MailStore, settings: AISettingsStore, provider: AIProvider? = nil) {
        self.store = store
        self.settings = settings
        override = provider
    }

    /// O modelo que vale agora, ou nil se a IA estiver desligada/indisponível.
    public func provider() -> AIProvider? {
        if let override { return override }
        let s = settings.load()
        if s.localEnabled, FoundationModelsProvider.isAvailable { return FoundationModelsProvider() }
        if s.cloudEnabled, !s.openRouterKey.isEmpty { return OpenRouterProvider(key: s.openRouterKey, model: s.openRouterModel) }
        return nil
    }

    /// Processa até `max` mensagens sem Tipo da pasta. Devolve quantas classificou. Nunca lança; erro fica em `lastError`.
    @discardableResult
    public func run(folder: String, max: Int = 50) async -> Int {
        var done = 0
        do {
            // ponytail: sequencial, uma mensagem por vez; paralelizar se a nuvem ficar lenta (o local é serial de qualquer forma).
            for m in try store.unclassified(in: folder, limit: max) where await classify(m) { done += 1 }
        } catch {
            lastError = error.localizedDescription
        }
        return done
    }

    @discardableResult
    public func classify(_ id: String) async -> Bool {
        guard let m = try? store.message(id: id) else { return false }
        return await classify(m)
    }

    private func classify(_ m: StoredMessage) async -> Bool {
        do {
            if let rule = RulesEngine.match(m, rules: try store.rules()), let tipo = rule.tipo.flatMap(Tipo.init(rawValue:)) {
                let c = Classification(tipo: tipo, justificativa: rule.explanation ?? "\(rule.field.rawValue) = \(rule.value)", categoria: rule.categoria)
                try store.saveClassification(id: m.id, c, byRule: true)
                if let rid = rule.id { try store.countRuleHit(id: rid) }
                return true
            }
            guard let provider = provider() else { return false }
            let c = try await Classifier(provider: provider).classify(m)
            try store.saveClassification(id: m.id, c)
            return true
        } catch {
            lastError = "\(m.subject.prefix(40)): \(error.localizedDescription)"
            return false
        }
    }
}
