import Foundation

/// Configuração do cliente público no Entra. Sem segredo: só client ID e redirect (ADR 0007).
public struct OAuthConfig: Sendable {
    public var clientID: String
    public var redirectURI: String
    public var tenant: String
    public var scopes: [String]

    public init(
        clientID: String,
        redirectURI: String,
        tenant: String = "common",
        scopes: [String] = ["offline_access", "User.Read", "Mail.ReadWrite", "Mail.Send"]
    ) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.tenant = tenant
        self.scopes = scopes
    }

    var authorizeURL: URL { URL(string: "https://login.microsoftonline.com/\(tenant)/oauth2/v2.0/authorize")! }
    var tokenURL: URL { URL(string: "https://login.microsoftonline.com/\(tenant)/oauth2/v2.0/token")! }
}

public struct Tokens: Codable, Sendable, Equatable {
    public var accessToken: String
    public var refreshToken: String
    public var expiresAt: Date

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// Margem de 60 s para não usar um token que expira durante a requisição.
    public var isExpired: Bool { expiresAt.timeIntervalSinceNow < 60 }
}

public enum OAuthError: Error, LocalizedError, Sendable {
    case invalidCallback
    case stateMismatch
    case server(code: String, description: String?)
    case invalidResponse(status: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidCallback: "O login não devolveu um código de autorização."
        case .stateMismatch: "A resposta do login não corresponde ao pedido (state)."
        case let .server(code, description): "\(code): \(description ?? "sem detalhe")"
        case let .invalidResponse(status): "Resposta inesperada do servidor de login (HTTP \(status))."
        }
    }
}

/// Fluxo Authorization Code + PKCE contra o endpoint v2 do Entra. Funções puras; quem abre o navegador é o app.
public enum OAuth {
    public static func authorizationURL(config: OAuthConfig, pkce: PKCE, state: String) -> URL {
        var components = URLComponents(url: config.authorizeURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "client_id", value: config.clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: config.redirectURI),
            .init(name: "response_mode", value: "query"),
            .init(name: "scope", value: config.scopes.joined(separator: " ")),
            .init(name: "state", value: state),
            .init(name: "code_challenge", value: pkce.challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "prompt", value: "select_account"),
        ]
        return components.url!
    }

    /// Extrai o `code` do callback, conferindo o `state`.
    public static func code(fromCallback url: URL, expectedState: String) throws -> String {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        if let error = value("error") { throw OAuthError.server(code: error, description: value("error_description")) }
        guard value("state") == expectedState else { throw OAuthError.stateMismatch }
        guard let code = value("code"), !code.isEmpty else { throw OAuthError.invalidCallback }
        return code
    }

    public static func exchange(code: String, pkce: PKCE, config: OAuthConfig, session: URLSession = .shared) async throws -> Tokens {
        try await tokenRequest(config: config, session: session, form: [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": config.redirectURI,
            "code_verifier": pkce.verifier,
        ])
    }

    public static func refresh(_ tokens: Tokens, config: OAuthConfig, session: URLSession = .shared) async throws -> Tokens {
        var refreshed = try await tokenRequest(config: config, session: session, form: [
            "grant_type": "refresh_token",
            "refresh_token": tokens.refreshToken,
        ])
        // O Entra pode omitir o refresh token novo; nesse caso o antigo continua válido.
        if refreshed.refreshToken.isEmpty { refreshed.refreshToken = tokens.refreshToken }
        return refreshed
    }

    private struct TokenResponse: Decodable {
        var access_token: String
        var refresh_token: String?
        var expires_in: Int
    }

    private struct ErrorResponse: Decodable {
        var error: String
        var error_description: String?
    }

    private static func tokenRequest(config: OAuthConfig, session: URLSession, form: [String: String]) async throws -> Tokens {
        var request = URLRequest(url: config.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var body = form
        body["client_id"] = config.clientID
        body["scope"] = config.scopes.joined(separator: " ")
        request.httpBody = formEncoded(body).data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200 ..< 300).contains(status) else {
            if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw OAuthError.server(code: err.error, description: err.error_description)
            }
            throw OAuthError.invalidResponse(status: status)
        }
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        return Tokens(
            accessToken: token.access_token,
            refreshToken: token.refresh_token ?? "",
            expiresAt: Date().addingTimeInterval(TimeInterval(token.expires_in))
        )
    }

    static func formEncoded(_ form: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return form.keys.sorted().map { key in
            "\(key)=\(form[key]!.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")"
        }.joined(separator: "&")
    }
}
