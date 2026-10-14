import Foundation

public enum GraphError: Error, LocalizedError, Sendable {
    case notSignedIn
    case http(status: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn: "Nenhuma conta conectada."
        case let .http(status, body): "Graph respondeu HTTP \(status): \(body.prefix(300))"
        }
    }
}

/// Cliente do Microsoft Graph com renovação automática de token. Um por conta.
public actor GraphClient {
    public static let baseURL = URL(string: "https://graph.microsoft.com/v1.0")!

    private let config: OAuthConfig
    private let store: TokenStore
    private let session: URLSession
    private var tokens: Tokens?
    private var refreshTask: Task<Tokens, Error>?
    private var authGeneration = UUID()
    private var retryNotBefore = Date.distantPast
    private var throttleError: GraphError?

    public init(config: OAuthConfig, store: TokenStore, session: URLSession = .shared) {
        self.config = config
        self.store = store
        self.session = session
        tokens = store.load()
        // Token de um login com escopos antigos: tratar como deslogado para pedir consentimento dos novos.
        if let t = tokens, Set(t.scopes ?? []) != Set(config.scopes) {
            tokens = nil
            store.clear()
        }
    }

    public var isSignedIn: Bool { tokens != nil }

    public func signIn(_ tokens: Tokens) throws {
        try store.save(tokens)
        authGeneration = UUID()
        self.tokens = tokens
    }

    public func signOut() {
        authGeneration = UUID()
        refreshTask?.cancel()
        refreshTask = nil
        tokens = nil
        store.clear()
    }

    public func get<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = [], headers: [String: String] = [:]) async throws -> T {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        return try await get(url: components.url!, headers: headers)
    }

    /// GET numa URL completa (nextLink / deltaLink devolvidos pelo Graph).
    public func get<T: Decodable & Sendable>(url: URL, headers: [String: String] = [:]) async throws -> T {
        let data = try await send(method: "GET", url: url, body: nil, headers: headers)
        return try Self.decoder.decode(T.self, from: data)
    }

    public func post(_ path: String, json: Data) async throws {
        _ = try await send(method: "POST", url: Self.baseURL.appendingPathComponent(path), body: json, headers: [:])
    }

    public func postDecoding<T: Decodable & Sendable>(_ path: String, json: Data) async throws -> T {
        let data = try await send(method: "POST", url: Self.baseURL.appendingPathComponent(path), body: json, headers: [:])
        return try Self.decoder.decode(T.self, from: data)
    }

    public func delete(_ path: String) async throws {
        _ = try await send(method: "DELETE", url: Self.baseURL.appendingPathComponent(path), body: nil, headers: [:])
    }

    public func patch(_ path: String, json: Data) async throws {
        _ = try await send(method: "PATCH", url: Self.baseURL.appendingPathComponent(path), body: json, headers: [:])
    }

    private func send(method: String, url: URL, body: Data?, headers: [String: String]) async throws -> Data {
        if Date() < retryNotBefore, let throttleError { throw throttleError }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(try await validAccessToken())", forHTTPHeaderField: "Authorization")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let generation = authGeneration
        let (data, response) = try await session.data(for: request)
        guard generation == authGeneration else { throw GraphError.notSignedIn }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200 ..< 300).contains(status) else {
            if status == 401 { signOut() }
            let error = GraphError.http(status: status, body: String(decoding: data, as: UTF8.self))
            if status == 429 || status == 503 {
                let retry = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Retry-After")
                let seconds = retry.flatMap(TimeInterval.init) ?? 60
                retryNotBefore = Date().addingTimeInterval(max(1, seconds))
                throttleError = error
            }
            throw error
        }
        return data
    }

    /// Token válido para chamadas feitas fora do cliente (ex.: download de MIME).
    public func bearer() async throws -> String { try await validAccessToken() }

    private func validAccessToken() async throws -> String {
        guard let current = tokens else { throw GraphError.notSignedIn }
        guard current.isExpired else { return current.accessToken }
        let generation = authGeneration
        if let refreshTask {
            let refreshed = try await refreshTask.value
            guard authGeneration == generation, tokens != nil else { throw GraphError.notSignedIn }
            return refreshed.accessToken
        }
        let task = Task { try await OAuth.refresh(current, config: config, session: session) }
        refreshTask = task
        defer { if authGeneration == generation { refreshTask = nil } }
        let refreshed = try await task.value
        guard authGeneration == generation, tokens != nil else { throw GraphError.notSignedIn }
        try store.save(refreshed)
        tokens = refreshed
        return refreshed.accessToken
    }

    /// O Graph devolve datas ISO 8601 com até 7 casas decimais; o decoder padrão não aceita fração.
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            // Trunca para 3 casas: o parser ISO 8601 só aceita milissegundos.
            let normalized = raw.replacing(/\.(\d{3})\d+/) { ".\($0.output.1)" }
            if let date = try? Date(normalized, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) { return date }
            if let date = try? Date(raw, strategy: Date.ISO8601FormatStyle()) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data inválida: \(raw)")
        }
        return decoder
    }()
}
