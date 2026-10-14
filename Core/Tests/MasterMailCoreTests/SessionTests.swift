import Foundation
import MasterMailCore
import Testing

struct SessionTests {
    private func reopen(_ fixture: HTTPFixture) -> GraphClient {
        GraphClient(config: OAuthConfig(clientID: "test", redirectURI: "test://auth"),
                    store: TokenStore(fileURL: fixture.directory.appendingPathComponent("tokens.json")),
                    session: fixture.makeSession())
    }

    @Test func reopeningAppRenewsSavedSessionWithoutInteractiveLogin() async throws {
        let fixture = HTTPFixture([
            .init(body: #"{"access_token":"renewed","refresh_token":"rotated","expires_in":3600}"#),
            .init(body: #"{"id":"test-account","mail":"person@example.test"}"#),
            .init(body: #"{"id":"test-account","mail":"person@example.test"}"#),
        ])
        _ = try fixture.graph(expired: true)
        let reopened = reopen(fixture)
        #expect(await reopened.isSignedIn)
        _ = try await reopened.me()
        let saved = TokenStore(fileURL: fixture.directory.appendingPathComponent("tokens.json")).load()
        #expect(saved?.refreshToken == "rotated")
        _ = try await reopen(fixture).me()
        #expect(fixture.requests.count == 3)
        #expect(fixture.requests.first?.url?.path.hasSuffix("/token") == true)
        #expect(fixture.requests.filter { $0.url?.path.hasSuffix("/token") == true }.count == 1)
        #expect(fixture.requests.last?.value(forHTTPHeaderField: "Authorization") == "Bearer renewed")
    }

    @Test func rejectedAccessTokenRenewsAndKeepsExistingRefreshToken() async throws {
        let fixture = HTTPFixture([
            .init(status: 401),
            .init(body: #"{"access_token":"renewed","expires_in":3600}"#),
            .init(body: #"{"mail":"person@example.test"}"#),
        ])
        let graph = try fixture.graph()
        _ = try await graph.me()
        #expect(await graph.isSignedIn)
        #expect(fixture.requests.count == 3)
        #expect(fixture.requests.last?.value(forHTTPHeaderField: "Authorization") == "Bearer renewed")
        #expect(TokenStore(fileURL: fixture.directory.appendingPathComponent("tokens.json")).load()?.refreshToken == "fake-refresh")
    }

    @Test func temporaryRenewalFailureKeepsSessionAcrossRestart() async throws {
        let fixture = HTTPFixture([
            .init(status: 503, body: #"{"error":"temporarily_unavailable"}"#),
            .init(body: #"{"access_token":"renewed","refresh_token":"rotated","expires_in":3600}"#),
            .init(body: #"{"mail":"person@example.test"}"#),
        ])
        let graph = try fixture.graph(expired: true)
        do {
            _ = try await graph.me()
            Issue.record("A falha temporária deveria ser informada")
        } catch {}
        #expect(await graph.isSignedIn)
        let reopened = reopen(fixture)
        _ = try await reopened.me()
        #expect(await reopened.isSignedIn)
    }

    @Test func repeatedUnauthorizedDoesNotEraseSavedAuthorizationOrRetryForever() async throws {
        let fixture = HTTPFixture([
            .init(status: 401),
            .init(body: #"{"access_token":"renewed","refresh_token":"rotated","expires_in":3600}"#),
            .init(status: 401),
        ])
        let graph = try fixture.graph()
        do {
            _ = try await graph.me()
            Issue.record("O segundo 401 deveria ser informado")
        } catch let error as GraphError {
            guard case .http(status: 401, body: _) = error else { throw error }
        }
        #expect(await graph.isSignedIn)
        #expect(await reopen(fixture).isSignedIn)
        #expect(fixture.requests.count == 3)
    }

    @Test func explicitlyRevokedRefreshTokenRequiresNewLogin() async throws {
        let fixture = HTTPFixture([.init(status: 400, body: #"{"error":"invalid_grant"}"#)])
        let graph = try fixture.graph(expired: true)
        do {
            _ = try await graph.me()
            Issue.record("A revogação deveria ser informada")
        } catch let error as OAuthError { #expect(error.requiresSignIn) }
        #expect(await graph.isSignedIn == false)
        #expect(await reopen(fixture).isSignedIn == false)
    }
}
