import Foundation
@testable import MasterMailCore
import Testing

struct OAuthTests {
    /// Vetor oficial do RFC 7636, apêndice B.
    @Test func pkceChallengeMatchesRFC() {
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func randomVerifierIsURLSafeAndLongEnough() {
        let pkce = PKCE()
        #expect(pkce.verifier.count >= 43)
        #expect(pkce.verifier.allSatisfy { $0.isLetter || $0.isNumber || "-_".contains($0) })
    }

    @Test func callbackParsingChecksStateAndErrors() throws {
        let ok = URL(string: "msauth.test://auth?code=abc&state=xyz")!
        #expect(try OAuth.code(fromCallback: ok, expectedState: "xyz") == "abc")
        let wrongState = URL(string: "msauth.test://auth?code=abc&state=nope")!
        #expect(throws: OAuthError.self) { try OAuth.code(fromCallback: wrongState, expectedState: "xyz") }
        let denied = URL(string: "msauth.test://auth?error=access_denied&error_description=user%20cancelled&state=xyz")!
        #expect(throws: OAuthError.self) { try OAuth.code(fromCallback: denied, expectedState: "xyz") }
    }

    @Test func tokenStoreRoundTripsWithPrivatePermissions() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = TokenStore(fileURL: dir.appendingPathComponent("tokens.json"))
        let tokens = Tokens(accessToken: "a", refreshToken: "r", expiresAt: Date(timeIntervalSince1970: 1_800_000_000))
        try store.save(tokens)
        #expect(store.load() == tokens)
        let perms = try FileManager.default.attributesOfItem(atPath: store.fileURL.path)[.posixPermissions] as? Int
        #expect(perms == 0o600)
        store.clear()
        #expect(store.load() == nil)
    }

    @Test func graphDecoderAcceptsSevenFractionalDigits() throws {
        let json = Data(#"{"id":"1","receivedDateTime":"2026-10-13T12:34:56.1234567Z","isRead":true,"hasAttachments":false}"#.utf8)
        let message = try GraphClient.decoder.decode(Message.self, from: json)
        #expect(Int(message.receivedDateTime.timeIntervalSince1970) == 1_791_894_896)
    }
}
