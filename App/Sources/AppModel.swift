import AuthenticationServices
import Foundation
import MasterMailCore
import Observation

/// Estado do app: conta, Caixa de Entrada (do Índice local) e mensagem aberta. Um só, na main thread.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case needsClientID
        case signedOut
        case signedIn(account: String)
    }

    private(set) var phase: Phase = .needsClientID
    private(set) var messages: [StoredMessage] = []
    private(set) var openMessage: StoredMessage?
    /// A Conversa da mensagem aberta, cronológica, com Ramos.
    private(set) var conversation: [ConversationNode] = []
    var expanded: Set<String> = []
    private(set) var isSyncing = false
    /// Quantidade de mensagens processadas na sincronização em curso (primeira indexação é longa).
    private(set) var syncProgress = 0
    var searchText = "" { didSet { if searchText != oldValue { Task { await reloadList() } } } }
    var errorMessage: String?

    private var graph: GraphClient?
    private var sync: MailSync?
    private let tokenStore = TokenStore.default()
    private let store: MailStore
    private var pollTask: Task<Void, Never>?

    static let redirectScheme = "msauth.\(Bundle.main.bundleIdentifier ?? "io.github.victortabs.mastermail")"
    static let clientIDDefaultsKey = "MasterMailClientID"
    static let folder = "inbox"

    init() {
        do {
            store = try MailStore(path: MailStore.defaultPath())
        } catch {
            fatalError("Não abriu o Índice local: \(error)")
        }
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
        let client = GraphClient(config: config, store: tokenStore)
        graph = client
        sync = MailSync(graph: client, store: store)
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
        pollTask?.cancel()
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
            await reloadList()
            startPolling()
        } catch {
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }

    // MARK: Sincronização (polling de 60 s com o app aberto, ADR 0003)

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func refresh() async {
        guard let sync, !isSyncing else { return }
        isSyncing = true
        syncProgress = 0
        defer { isSyncing = false }
        do {
            try await sync.sync(folder: Self.folder) { [weak self] count in
                Task { @MainActor in self?.syncProgress = count }
            }
            await reloadList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Caixa de Entrada e busca (tudo do Índice local)

    func reloadList() async {
        do {
            messages = searchText.isEmpty
                ? try store.messages(in: Self.folder)
                : try store.search(searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func open(_ message: StoredMessage) async {
        openMessage = message
        expanded = [message.id]
        do {
            let thread = try message.conversationId.map { try store.conversation(id: $0) } ?? [message]
            conversation = ConversationTree.build(thread.isEmpty ? [message] : thread)
            await ensureHTML(id: message.id)
            if !message.isRead, let graph {
                try store.setRead(id: message.id, true)
                if let i = messages.firstIndex(where: { $0.id == message.id }) { messages[i].isRead = true }
                openMessage?.isRead = true
                try await graph.markRead(id: message.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ id: String) async {
        if expanded.contains(id) { expanded.remove(id); return }
        expanded.insert(id)
        await ensureHTML(id: id)
    }

    /// Mensagem fora da retenção de HTML: baixa o corpo na hora e guarda.
    private func ensureHTML(id: String) async {
        guard let i = conversation.firstIndex(where: { $0.id == id }),
              conversation[i].message.bodyHTML == nil, let graph else { return }
        do {
            guard let html = try await graph.bodyHTML(id: id) else { return }
            var m = conversation[i].message
            m.bodyHTML = html
            try store.upsert([m])
            if conversation.indices.contains(i), conversation[i].id == id { conversation[i].message = m }
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
