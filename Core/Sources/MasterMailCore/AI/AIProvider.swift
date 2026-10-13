import Foundation

/// Um modelo de linguagem que responde a um prompt. Implementações: local (Foundation Models) e nuvem (OpenRouter).
public protocol AIProvider: Sendable {
    var name: String { get }
    func complete(system: String, user: String, maxTokens: Int) async throws -> String
}

public enum AIError: Error, LocalizedError, Sendable {
    case unavailable(String)
    case badResponse(String)

    public var errorDescription: String? {
        switch self {
        case let .unavailable(s): s
        case let .badResponse(s): "Resposta inesperada do modelo: \(s.prefix(300))"
        }
    }
}
