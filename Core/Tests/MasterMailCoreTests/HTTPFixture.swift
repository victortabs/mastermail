import Foundation
import MasterMailCore

/// Servidor simulado por sessão. Os testes nunca acessam tokens nem a caixa postal real.
final class HTTPFixture: @unchecked Sendable {
    struct Reply: Sendable {
        var status: Int = 200
        var body: String = "{}"
        var headers: [String: String] = [:]
        var delay: Duration = .zero
    }
    private let lock = NSLock()
    private var replies: [Reply]
    private var received: [URLRequest] = []
    let id = UUID().uuidString
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    init(_ replies: [Reply]) {
        self.replies = replies
        FixtureProtocol.registry.register(self)
    }

    var requests: [URLRequest] { lock.withLock { received } }
    func next(_ request: URLRequest) -> Reply {
        lock.withLock {
            received.append(request)
            return replies.isEmpty ? Reply(status: 500, body: "Resposta simulada ausente") : replies.removeFirst()
        }
    }

    func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FixtureProtocol.self]
        config.httpAdditionalHeaders = ["X-Fixture-ID": id]
        return URLSession(configuration: config)
    }

    func graph(expired: Bool = false) throws -> GraphClient {
        let store = TokenStore(fileURL: directory.appendingPathComponent("tokens.json"))
        try store.save(Tokens(accessToken: "fake", refreshToken: "fake-refresh", expiresAt: expired ? .distantPast : .distantFuture, scopes: OAuthConfig.defaultScopes))
        return GraphClient(config: OAuthConfig(clientID: "test", redirectURI: "test://auth"), store: store, session: makeSession())
    }

    static func message(_ id: String) -> String {
        #"{"id":"\#(id)","subject":"Teste","receivedDateTime":"2026-10-13T10:00:00Z","isRead":false,"hasAttachments":false}"#
    }
}

private final class FixtureRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var fixtures: [String: HTTPFixture] = [:]
    func register(_ fixture: HTTPFixture) { lock.withLock { fixtures[fixture.id] = fixture } }
    func get(_ id: String) -> HTTPFixture? { lock.withLock { fixtures[id] } }
}

private final class FixtureProtocol: URLProtocol, @unchecked Sendable {
    static let registry = FixtureRegistry()
    private var responseTask: Task<Void, Never>?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let fixture = Self.registry.get(request.value(forHTTPHeaderField: "X-Fixture-ID") ?? "") else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL)); return
        }
        let reply = fixture.next(request)
        responseTask = Task {
            do { try await Task.sleep(for: reply.delay) } catch { return }
            let response = HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: nil, headerFields: reply.headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() { responseTask?.cancel() }
}
