import Foundation

/// Nuvem via OpenRouter (API compatível com OpenAI), com a chave do próprio usuário (ADR 0004).
public struct OpenRouterProvider: AIProvider {
    public let name: String
    public let key: String
    public let model: String
    let session: URLSession

    public init(key: String, model: String, session: URLSession = .shared) {
        self.key = key
        self.model = model
        self.session = session
        name = "OpenRouter (\(model))"
    }

    public enum Failure: Error, LocalizedError, Sendable {
        case http(status: Int, body: String)
        case empty

        public var errorDescription: String? {
            switch self {
            case .http(401, _): "OpenRouter recusou a chave de API (HTTP 401). Confira a chave nos ajustes de IA."
            case .http(402, _): "OpenRouter: sem créditos na conta (HTTP 402)."
            case .http(429, _): "OpenRouter: limite de requisições atingido (HTTP 429). Tente de novo em instantes."
            case let .http(status, body): "OpenRouter respondeu HTTP \(status): \(body.prefix(300))"
            case .empty: "OpenRouter devolveu uma resposta sem conteúdo."
            }
        }
    }

    private struct Request: Encodable {
        struct Msg: Encodable { let role: String; let content: String }
        let model: String
        let messages: [Msg]
        let temperature: Double
        let max_tokens: Int
    }

    private struct Response: Decodable {
        struct Choice: Decodable {
            struct Msg: Decodable { let content: String? }
            let message: Msg
        }
        let choices: [Choice]
    }

    public func complete(system: String, user: String, maxTokens: Int) async throws -> String {
        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("https://github.com/victortabs/mastermail", forHTTPHeaderField: "HTTP-Referer")
        req.setValue("MasterMail", forHTTPHeaderField: "X-Title")
        req.httpBody = try JSONEncoder().encode(Request(
            model: model,
            messages: [.init(role: "system", content: system), .init(role: "user", content: user)],
            temperature: 0,
            max_tokens: maxTokens))
        let (data, resp) = try await session.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw Failure.http(status: status, body: String(decoding: data, as: UTF8.self))
        }
        guard let content = try JSONDecoder().decode(Response.self, from: data).choices.first?.message.content,
              !content.isEmpty else { throw Failure.empty }
        return content
    }
}
