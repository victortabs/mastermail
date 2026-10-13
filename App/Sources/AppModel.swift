import AuthenticationServices
import Foundation
import MasterMailCore
import Observation

/// Estado do app: conta, pastas, lista (do Índice local) e Conversa aberta. Um só, na main thread.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case needsClientID
        case signedOut
        case signedIn(account: String)
    }

    private(set) var phase: Phase = .needsClientID
    /// O que está selecionado na lateral: uma pasta da conta ou uma Pasta local.
    enum SidebarItem: Hashable {
        case account(WellKnownFolder)
        case local(String)
    }

    /// Pastas do servidor: só para indexar tudo e para contadores. Nunca aparecem como navegação.
    private(set) var folders: [MailFolder] = []
    private(set) var wellKnown: [WellKnownFolder: String] = [:]
    private(set) var localFolders: [String] = []
    var selection: SidebarItem? = .account(.inbox) { didSet { if selection != oldValue { Task { await folderChanged() } } } }
    /// Pasta do servidor correspondente à seleção (nil para Pasta local).
    var selectedFolderID: String? {
        if case let .account(known) = selection { return wellKnown[known] }
        return nil
    }
    private(set) var messages: [StoredMessage] = []
    private(set) var hasMore = false
    private(set) var openMessage: StoredMessage?
    /// A Conversa da mensagem aberta, cronológica, com Ramos.
    private(set) var conversation: [ConversationNode] = []
    var expanded: Set<String> = []
    /// Mensagens em que o usuário liberou imagens remotas (só nesta sessão).
    var remoteImagesAllowed: Set<String> = []
    private(set) var isSyncing = false
    private(set) var syncStatus = ""
    var searchText = "" { didSet { if searchText != oldValue { Task { await reloadList() } } } }
    var errorMessage: String?

    private var graph: GraphClient?
    private var sync: MailSync?
    private let tokenStore = TokenStore.default()
    private let store: MailStore
    private var pollTask: Task<Void, Never>?
    private var backfillTask: Task<Void, Never>?
    private static let pageSize = 300

    static let redirectScheme = "msauth.\(Bundle.main.bundleIdentifier ?? "io.github.victortabs.mastermail")"
    static let clientIDDefaultsKey = "MasterMailClientID"

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
        backfillTask?.cancel()
        await graph?.signOut()
        messages = []
        folders = []
        openMessage = nil
        conversation = []
        phase = .signedOut
    }

    private func loadAccount() async {
        guard let graph else { return }
        do {
            let me = try await graph.me()
            phase = .signedIn(account: me.mail ?? me.userPrincipalName ?? "conta")
            await loadFolders()
            reloadLocalFolders()
            await folderChanged()
            startPolling()
            startBackfill()
        } catch {
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }

    // MARK: Pastas do servidor (só leitura)

    func loadFolders() async {
        guard let graph else { return }
        do {
            async let known = graph.wellKnownFolderIDs()
            async let list = graph.folders()
            wellKnown = try await known
            folders = try await list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func folder(_ id: String?) -> MailFolder? { folders.first { $0.id == id } }

    func unreadCount(_ known: WellKnownFolder) -> Int { folder(wellKnown[known])?.unreadItemCount ?? 0 }

    // MARK: Pastas locais (CONTEXT.md; ADR 0006: gravadas na mensagem, no servidor)

    private func reloadLocalFolders() {
        localFolders = (try? store.localFolders()) ?? []
    }

    func createLocalFolder(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? store.createLocalFolder(trimmed)
        reloadLocalFolders()
        selection = .local(trimmed)
    }

    func renameLocalFolder(_ old: String, to new: String) async {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != old else { return }
        do {
            let ids = try store.renameLocalFolder(old, to: trimmed)
            reloadLocalFolders()
            if selection == .local(old) { selection = .local(trimmed) }
            for id in ids { try await graph?.setLocalFolder(id: id, trimmed) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Move para uma Pasta local (nil = volta para a Caixa de entrada). Local primeiro, servidor depois.
    func moveToLocalFolder(_ id: String, _ name: String?) async {
        do {
            if let name { try store.createLocalFolder(name) }
            try store.setLocalFolder(id: id, name)
            reloadLocalFolders()
            messages.removeAll { $0.id == id }
            if openMessage?.id == id { openMessage = nil; conversation = [] }
            try await graph?.setLocalFolder(id: id, name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func folderChanged() async {
        openMessage = nil
        conversation = []
        await reloadList()
        if let id = selectedFolderID, (try? store.hasSynced(folder: id)) != true {
            await syncFolder(id)
        }
    }

    // MARK: Sincronização (polling de 60 s com o app aberto, ADR 0003)

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                guard let self else { return }
                var ids = Set([self.wellKnown[.inbox], self.selectedFolderID].compactMap { $0 })
                if tick % 10 == 9 { ids.formUnion(self.folders.map(\.id)) } // a cada 10 min, todas
                for id in ids { await self.syncFolder(id) }
                if tick % 10 == 9 { await self.loadFolders() }
                tick += 1
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    /// Primeira indexação de todas as pastas, em sequência, começando pela Caixa de Entrada.
    private func startBackfill() {
        backfillTask?.cancel()
        backfillTask = Task { [weak self] in
            guard let self else { return }
            let ordered = [self.wellKnown[.inbox], self.wellKnown[.sentitems]].compactMap { $0 } + self.folders.map(\.id)
            var seen = Set<String>()
            for id in ordered where seen.insert(id).inserted {
                if Task.isCancelled { return }
                await self.syncFolder(id)
            }
        }
    }

    func refresh() async {
        if let id = selectedFolderID { await syncFolder(id) }
        await loadFolders()
    }

    private var syncing = Set<String>()

    private func syncFolder(_ id: String) async {
        guard let sync, !syncing.contains(id) else { return }
        syncing.insert(id)
        isSyncing = true
        let name = folder(id)?.displayName ?? "pasta"
        defer {
            syncing.remove(id)
            isSyncing = !syncing.isEmpty
            if !isSyncing { syncStatus = "" }
        }
        do {
            try await sync.sync(folder: id) { [weak self] count in
                Task { @MainActor in self?.syncStatus = "\(name): \(count)" }
            }
            if id == selectedFolderID { await reloadList() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Lista e busca (tudo do Índice local)

    private func page(offset: Int) throws -> [StoredMessage] {
        switch selection {
        case let .local(name): try store.messages(localFolder: name, limit: Self.pageSize, offset: offset)
        case .account: try selectedFolderID.map { try store.messages(in: $0, limit: Self.pageSize, offset: offset) } ?? []
        case nil: []
        }
    }

    func reloadList() async {
        do {
            if searchText.isEmpty {
                let page = try page(offset: 0)
                messages = page
                hasMore = page.count == Self.pageSize
            } else {
                messages = try store.search(searchText)
                hasMore = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard hasMore, searchText.isEmpty else { return }
        do {
            let page = try page(offset: messages.count)
            messages += page
            hasMore = page.count == Self.pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Conversa

    func open(_ message: StoredMessage) async {
        openMessage = message
        expanded = [message.id]
        do {
            let thread = try message.conversationId.map { try store.conversation(id: $0) } ?? [message]
            conversation = ConversationTree.build(thread.isEmpty ? [message] : thread)
            await prepareBody(id: message.id)
            if !message.isRead { await setRead(message.id, true) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ id: String) async {
        if expanded.contains(id) { expanded.remove(id); return }
        expanded.insert(id)
        await prepareBody(id: id)
    }

    /// Garante HTML (mensagem antiga baixa na hora) e embute imagens inline (assinaturas).
    private func prepareBody(id: String) async {
        guard let i = conversation.firstIndex(where: { $0.id == id }), let graph else { return }
        var m = conversation[i].message
        do {
            if m.bodyHTML == nil, let html = try await graph.bodyHTML(id: id) { m.bodyHTML = html }
            if let html = m.bodyHTML, html.contains("cid:") {
                let inline = try await graph.inlineAttachments(messageID: id)
                m.bodyHTML = HTMLText.embedInline(html, attachments: inline)
            }
            guard m != conversation[i].message else { return }
            try store.upsert([m])
            if conversation.indices.contains(i), conversation[i].id == id { conversation[i].message = m }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Ações (local primeiro, servidor depois)

    func setRead(_ id: String, _ isRead: Bool) async {
        do {
            try store.setRead(id: id, isRead)
            if let i = messages.firstIndex(where: { $0.id == id }) { messages[i].isRead = isRead }
            if openMessage?.id == id { openMessage?.isRead = isRead }
            try await graph?.markRead(id: id, isRead)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Arquivar e Apagar são ações de servidor (CONTEXT.md). Some da lista na hora; o delta confirma depois.
    func move(_ id: String, to destination: WellKnownFolder) async {
        do {
            try store.delete(ids: [id])
            messages.removeAll { $0.id == id }
            if openMessage?.id == id { openMessage = nil; conversation = [] }
            try await graph?.move(id: id, to: destination)
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
