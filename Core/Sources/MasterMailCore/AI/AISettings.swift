import Foundation

/// Ajustes de IA (ADR 0004): local ligado por padrão, nuvem só com opt-in e chave do usuário.
public struct AISettings: Codable, Sendable, Equatable {
    public var localEnabled: Bool = true
    public var cloudEnabled: Bool = false
    public var openRouterKey: String = ""
    public var openRouterModel: String = "google/gemini-2.5-flash"
    /// Modelo para tarefas pesadas (Organizador, resumos longos): Haiku 5.5 tem 1M de contexto e custa pouco.
    public var openRouterHeavyModel: String = "anthropic/claude-haiku-5.5"

    public init() {}

    /// Decodifica tolerando chaves ausentes (arquivo de versão anterior).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        localEnabled = try c.decodeIfPresent(Bool.self, forKey: .localEnabled) ?? true
        cloudEnabled = try c.decodeIfPresent(Bool.self, forKey: .cloudEnabled) ?? false
        openRouterKey = try c.decodeIfPresent(String.self, forKey: .openRouterKey) ?? ""
        openRouterModel = try c.decodeIfPresent(String.self, forKey: .openRouterModel) ?? "google/gemini-2.5-flash"
        openRouterHeavyModel = try c.decodeIfPresent(String.self, forKey: .openRouterHeavyModel) ?? "anthropic/claude-haiku-5.5"
    }
}

/// Guarda os ajustes num arquivo 0600 (contém a chave da OpenRouter), como o TokenStore.
public struct AISettingsStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    /// `~/Library/Application Support/MasterMail/ai.json`
    public static func `default`() -> AISettingsStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return AISettingsStore(fileURL: base.appendingPathComponent("MasterMail/ai.json"))
    }

    public func load() -> AISettings {
        guard let data = try? Data(contentsOf: fileURL),
              let s = try? JSONDecoder().decode(AISettings.self, from: data) else { return AISettings() }
        return s
    }

    public func save(_ settings: AISettings) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(settings).write(to: fileURL, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
