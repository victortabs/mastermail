import AuthenticationServices
import Foundation
import MasterMailCore
import Observation

/// Estado do app: conta, Caixa de Entrada e mensagem aberta. Um só, na main thread.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case needsClientID
        case signedOut
        case signedIn(account: String)
    }

    private(set) var phase: Phase = .needsClientID
    private(set) var messages: [Message] = []
    private(set) var openMessage: Message?
    private(set) var isLoading = false
    var errorMessage: String?

    private var graph: GraphClient?
    private let store = TokenStore.default()

    static let redirectScheme = "msauth.\(Bundle.main.bundleIdentifier ?? "io.github.victortabs.mastermail")"
    static let clientIDDefaultsKey = "MasterMailClientID"

    init() {
        if let id = Self.storedClientID { configure(clientID: id) }
    }

    /// Info.plist (via xcconfig) primeiro; senão o que o usuário colou na tela inicial.
    static var storedClientID: String? {
        let fromPlist = (Bundle.main.object(forInfoDictionaryKey: clientIDDefaultsKey) as? String)?.trimmingCharacters(in: .whitespaces)
        if let fromPlist, !fromPlist.isEmpty { return fromPlist }
        let fromDefaults = UserDefaults.standard.string(forKey: clientIDDefaultsKey)?.trimmingCharacters(in: .whitespaces)
        return (fromDefaults?.isEmpty == false) ? fromDefaults : nil
    }

    func saveClientID(_ id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: Self.clientIDDefaultsKey)
        configure(clientID: trimmed)
    }

    private func configure(clientID: String) {
        let config = OAuthConfig(clientID: clientID, redirectURI: "\(Self.redirectScheme)://auth")
        let client = GraphClient(config: config, store: store)
        graph = client
        phase = .signedOut
        Task {
            if await client.isSignedIn { await loadAccount() }
        }
    }

    // MARK: Login (ADR 0007: OAuth próprio via ASWebAuthenticationSession)

    func signIn() async {
        guard let graph, let clientID = Self.storedClientID else { return }
        let config = OAuthConfig(clientID: clientID, redirectURI: "\(Self.redirectScheme)://auth")
        let pkce = PKCE()
        let state = UUID().uuidString
        let url = OAuth.authorizationURL(config: config, pkce: pkce, state: state)
        do {
            let callback = try await WebAuth.run(url: url, callbackScheme: Self.redirectScheme)
            let code = try OAuth.code(fromCallback: callback, expectedState: state)
            let tokens = try await OAuth.exchange(code: code, pkce: pkce, config: config)
            try await graph.signIn(tokens)
            await loadAccount()
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // Usuário fechou a janela: nada a dizer.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        await graph?.signOut()
        messages = []
        openMessage = nil
        phase = .signedOut
    }

    private func loadAccount() async {
        guard let graph else { return }
        do {
            let me = try await graph.me()
            phase = .signedIn(account: me.mail ?? me.userPrincipalName ?? "conta")
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }

    // MARK: Caixa de Entrada

    func refresh() async {
        guard let graph else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await graph.inbox(top: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func open(_ message: Message) async {
        guard let graph else { return }
        openMessage = message
        do {
            let full = try await graph.message(id: message.id)
            guard openMessage?.id == message.id else { return }
            openMessage = full
            if !full.isRead {
                try await graph.markRead(id: message.id)
                if let i = messages.firstIndex(where: { $0.id == message.id }) { messages[i].isRead = true }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Abre a janela de login do sistema e devolve a URL de callback.
enum WebAuth {
    @MainActor
    static func run(url: URL, callbackScheme: String) async throws -> URL {
        let anchor = Anchor()
        return try await withCheckedThrowingContinuation { continuation in
            // O callback chega numa fila de fundo (XPC); @Sendable tira a isolação de MainActor herdada.
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { @Sendable callback, error in
                if let callback { continuation.resume(returning: callback) }
                else { continuation.resume(throwing: error ?? OAuthError.invalidCallback) }
            }
            session.presentationContextProvider = anchor
            session.prefersEphemeralWebBrowserSession = false
            session.start()
            // Mantém o provider vivo até o callback.
            withExtendedLifetime(anchor) {}
        }
    }

    private final class Anchor: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
            NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        }
    }
}
