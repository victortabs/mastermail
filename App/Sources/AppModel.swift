import AppKit
import AuthenticationServices
import Foundation
import MasterMailCore
import Observation
import UserNotifications

/// Estado do app: conta, pastas, lista (do Índice local), Conversa aberta, composição, desfazer. Um só, na main thread.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case needsClientID
        case signedOut
        case signedIn(account: String)
    }

    enum AppView: Hashable { case mail, calendar, people }

    /// O que está selecionado na lateral.
    enum SidebarItem: Hashable {
        case account(WellKnownFolder)
        case local(String)
        case snoozed
        case awaitingMe
        case awaitingThem
        case triage
        case noise
    }

    /// Uma ação que pode ser desfeita com `z`.
    struct UndoEntry {
        let title: String
        let undo: @MainActor () async -> Void
    }

    private(set) var phase: Phase = .needsClientID
    var view: AppView = .mail
    private(set) var calendar: CalendarModel?
    private(set) var accountEmail = ""

    /// Pastas do servidor: só para indexar tudo e para contadores. Nunca aparecem como navegação.
    private(set) var folders: [MailFolder] = []
    private(set) var wellKnown: [WellKnownFolder: String] = [:]
    private(set) var localFolders: [String] = []
    var selection: SidebarItem? = .account(.inbox) { didSet { if selection != oldValue { Task { await folderChanged() } } } }
    var selectedFolderID: String? {
        if case let .account(known) = selection { return wellKnown[known] }
        return nil
    }

    private(set) var messages: [StoredMessage] = []
    private(set) var hasMore = false
    private(set) var openMessage: StoredMessage?
    private(set) var conversation: [ConversationNode] = []
    var expanded: Set<String> = []
    /// Foco de teclado dentro da Conversa (Enter entra, Esc sai).
    var conversationFocused = false
    var focusedNodeID: String?
    var remoteImagesAllowed: Set<String> = []
    private(set) var isSyncing = false
    private(set) var syncStatus = ""
    var searchText = "" { didSet { if searchText != oldValue { Task { await reloadList() } } } }
    var errorMessage: String?

    /// Composição em curso. Responder/encaminhar aparecem inline na Conversa; nova mensagem em sheet.
    var compose: ComposeModel?
    private var pendingSend: Task<Void, Never>?

    private(set) var undoStack: [UndoEntry] = []
    private(set) var toast: String?
    private var toastTask: Task<Void, Never>?

    private var graph: GraphClient?
    var client: GraphClient? { graph }
    /// IA (ADR 0004): Regra → modelo local → nuvem opt-in. Roda depois de cada sincronização da Caixa de entrada.
    let aiSettings = AISettingsStore.default()
    private(set) var pipeline: ClassificationPipeline?
    private(set) var triageCount = 0
    private(set) var aiStatus = ""
    private var notified: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "notifiedIDs") ?? [])
    private var sync: MailSync?
    private let tokenStore = TokenStore.default()
    let store: MailStore
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
        calendar = CalendarModel(graph: client)
        pipeline = ClassificationPipeline(store: store, settings: aiSettings)
        phase = .signedOut
        Task { if await client.isSignedIn { await loadAccount() } }
    }

    // MARK: Login (ADR 0007)

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
            accountEmail = (me.mail ?? me.userPrincipalName ?? "").lowercased()
            phase = .signedIn(account: accountEmail.isEmpty ? "conta" : accountEmail)
            await loadFolders()
            reloadLocalFolders()
            await folderChanged()
            refreshCounters()
            startPolling()
            startBackfill()
            Task { await reconcileLocalFolders() }
            Task { await calendar?.load() }
        } catch {
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }

    // MARK: Pastas do servidor (só índice e contadores)

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

    // MARK: Pastas locais (ADR 0006)

    private func reloadLocalFolders() { localFolders = (try? store.localFolders()) ?? [] }

    private func reconcileLocalFolders() async {
        guard let graph else { return }
        do {
            try store.applyLocalFolders(try await graph.localFolderAssignments())
            reloadLocalFolders()
            await reloadList()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    func moveToLocalFolder(_ id: String, _ name: String?) async {
        guard let m = messages.first(where: { $0.id == id }) ?? (try? store.message(id: id)) else { return }
        let old = m.localFolder
        do {
            if let name { try store.createLocalFolder(name) }
            try store.setLocalFolder(id: id, name)
            reloadLocalFolders()
            removeFromList(id)
            try await graph?.setLocalFolder(id: id, name)
            pushUndo(name.map { "Movida para \($0)" } ?? "Tirada da pasta local") { [weak self] in
                guard let self else { return }
                try? store.setLocalFolder(id: id, old)
                try? await graph?.setLocalFolder(id: id, old)
                await reloadList()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Sincronização (polling de 60 s, ADR 0003)

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                guard let self else { return }
                var ids = Set([wellKnown[.inbox], selectedFolderID].compactMap { $0 })
                if tick % 10 == 9 { ids.formUnion(folders.map(\.id)) }
                for id in ids { await syncFolder(id) }
                if tick % 10 == 9 { await loadFolders() }
                if tick % 5 == 4 { await calendar?.loadToday() }
                tick += 1
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    private func startBackfill() {
        backfillTask?.cancel()
        backfillTask = Task { [weak self] in
            guard let self else { return }
            let ordered = [wellKnown[.inbox], wellKnown[.sentitems]].compactMap { $0 } + folders.map(\.id)
            var seen = Set<String>()
            for id in ordered where seen.insert(id).inserted {
                if Task.isCancelled { return }
                await syncFolder(id)
            }
        }
    }

    func refresh() async {
        if let id = selectedFolderID { await syncFolder(id) }
        await loadFolders()
        await reloadList()
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
            if id == wellKnown[.inbox] { await classifyInbox() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: IA (Tipo, Importante, Triagem, Regras)

    private func classifyInbox() async {
        guard let pipeline, let inbox = wellKnown[.inbox] else { return }
        let done = await pipeline.run(folder: inbox, max: 30)
        if let error = await pipeline.lastError { aiStatus = error } else if done > 0 { aiStatus = "" }
        refreshCounters()
        if done > 0 {
            if selection == .account(.inbox) || selection == .triage { await reloadList() }
            await notifyImportant()
        }
    }

    func refreshCounters() {
        guard let inbox = wellKnown[.inbox] else { return }
        triageCount = (try? store.triageCount(folder: inbox)) ?? 0
        let today = (try? store.receivedToday(folder: inbox)) ?? 0
        NSApplication.shared.dockTile.badgeLabel = today > 0 ? String(today) : nil
    }

    /// Notificação do Mac só para Importante (requisito), uma vez por mensagem.
    private func notifyImportant() async {
        guard let important = try? store.importantUnread(limit: 20) else { return }
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        for m in important where !notified.contains(m.id) {
            let content = UNMutableNotificationContent()
            content.title = m.fromName.isEmpty ? m.fromAddress : m.fromName
            content.subtitle = m.subject
            content.body = m.justificativa ?? m.preview
            try? await center.add(UNNotificationRequest(identifier: m.id, content: content, trigger: nil))
            notified.insert(m.id)
        }
        UserDefaults.standard.set(Array(notified.suffix(500)), forKey: "notifiedIDs")
    }

    /// `y` na Triagem: confirma o Ruído e grava o Tipo como Categoria no servidor (aparece no celular).
    func confirmNoise(_ id: String) async {
        guard let m = messages.first(where: { $0.id == id }) ?? (try? store.message(id: id)) else { return }
        do {
            try store.confirmTriage(id: id)
            removeFromList(id)
            refreshCounters()
            if let tipo = m.tipo.flatMap(Tipo.init(rawValue:)) {
                let categories = Array(Set(m.categories + [tipo.label]))
                try await graph?.setCategories(id: id, categories)
            }
            pushUndo("Confirmado como \(m.tipo.flatMap(Tipo.init(rawValue:))?.label ?? "ruído")") { [weak self] in
                try? self?.store.markNotNoise(id: id)
                self?.refreshCounters()
                await self?.reloadList()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// `n` na Triagem: discorda. A Explicação vira Regra (zero tokens dali em diante) e a mensagem volta à Caixa de entrada.
    func rejectNoise(_ id: String, explanation: String) async {
        guard let m = messages.first(where: { $0.id == id }) ?? (try? store.message(id: id)) else { return }
        do {
            try store.markNotNoise(id: id)
            removeFromList(id)
            refreshCounters()
            let text = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
            var rule = await RuleBuilder.fromExplanation(text, message: m, provider: pipeline?.provider())
            rule.tipo = Tipo.pessoa.rawValue
            if rule.explanation == nil || rule.explanation!.isEmpty { rule.explanation = text.isEmpty ? nil : text }
            try store.saveRule(rule)
            showToast("Regra criada: \(rule.field.rawValue) = \(rule.value) → Pessoa")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Lista e busca

    private func folderChanged() async {
        openMessage = nil
        conversation = []
        conversationFocused = false
        await reloadList()
        if let id = selectedFolderID, (try? store.hasSynced(folder: id)) != true { await syncFolder(id) }
    }

    private func page(offset: Int) throws -> [StoredMessage] {
        switch selection {
        case let .local(name): try store.messages(localFolder: name, limit: Self.pageSize, offset: offset)
        case .account(.inbox): try wellKnown[.inbox].map { try store.inboxMessages(folder: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .account: try selectedFolderID.map { try store.messages(in: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .triage: try wellKnown[.inbox].map { try store.triage(folder: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .noise: try wellKnown[.inbox].map { try store.noise(folder: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .snoozed: offset == 0 ? try store.snoozed() : []
        case .awaitingMe: offset == 0 ? try store.awaitingMyReply(inbox: wellKnown[.inbox] ?? "", me: accountEmail) : []
        case .awaitingThem: offset == 0 ? try store.awaitingTheirReply(sent: wellKnown[.sentitems] ?? "", me: accountEmail) : []
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

    private func removeFromList(_ id: String) {
        messages.removeAll { $0.id == id }
        if openMessage?.id == id { openMessage = nil; conversation = []; conversationFocused = false }
    }

    // MARK: Conversa

    /// Abre a Conversa: mais recente expandida (UX), a selecionada também, as outras recolhidas em uma linha.
    func open(_ message: StoredMessage) async {
        openMessage = message
        do {
            let thread = try message.conversationId.map { try store.conversation(id: $0) } ?? [message]
            conversation = ConversationTree.build(thread.isEmpty ? [message] : thread)
            let newest = conversation.last?.id ?? message.id
            expanded = [message.id, newest]
            focusedNodeID = newest
            await prepareBody(id: message.id)
            if newest != message.id { await prepareBody(id: newest) }
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

    func expandAll() async {
        for node in conversation { expanded.insert(node.id); await prepareBody(id: node.id) }
    }

    func moveFocus(_ delta: Int) {
        let ids = conversation.map(\.id)
        guard !ids.isEmpty else { return }
        let i = focusedNodeID.flatMap { ids.firstIndex(of: $0) } ?? ids.count - 1
        focusedNodeID = ids[min(max(i + delta, 0), ids.count - 1)]
    }

    private func prepareBody(id: String) async {
        guard let i = conversation.firstIndex(where: { $0.id == id }), let graph else { return }
        var m = conversation[i].message
        do {
            if m.bodyHTML == nil, let html = try await graph.bodyHTML(id: id) { m.bodyHTML = html }
            if let html = m.bodyHTML, html.contains("cid:") {
                m.bodyHTML = HTMLText.embedInline(html, attachments: try await graph.inlineAttachments(messageID: id))
            }
            guard m != conversation[i].message else { return }
            try store.upsert([m])
            if conversation.indices.contains(i), conversation[i].id == id { conversation[i].message = m }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Composição

    func startCompose(_ mode: ComposeModel.Mode) {
        guard let graph else { return }
        let signature = UserDefaults.standard.string(forKey: "signatureHTML") ?? ""
        let model = ComposeModel(mode: mode, graph: graph, signature: signature)
        compose = model
        Task { await model.start() }
    }

    /// Envio com 10 s de arrependimento (UX): fecha o editor na hora; `z` cancela e o rascunho fica em Rascunhos.
    func scheduleSend(_ model: ComposeModel) {
        compose = nil
        pendingSend?.cancel()
        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            await model.send()
            await MainActor.run {
                guard let self else { return }
                if let error = model.error { self.errorMessage = error } else { self.showToast("Enviada") }
                self.pendingSend = nil
            }
        }
        pendingSend = task
        pushUndo("Enviando em 10 s") { [weak self] in
            task.cancel()
            self?.pendingSend = nil
            self?.showToast("Envio cancelado. O rascunho está em Rascunhos.")
        }
    }

    // MARK: Ações (local primeiro, servidor depois, todas com desfazer)

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

    func toggleFlag(_ id: String) async {
        guard let m = messages.first(where: { $0.id == id }) else { return }
        let flagged = !m.isFlagged
        do {
            try store.setFlagged(id: id, flagged)
            if let i = messages.firstIndex(where: { $0.id == id }) { messages[i].isFlagged = flagged }
            try await graph?.setFlag(id: id, flagged)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Arquivar e Apagar são ações de servidor (CONTEXT.md). Some da lista na hora; desfazer traz de volta.
    func move(_ id: String, to destination: WellKnownFolder) async {
        guard let m = messages.first(where: { $0.id == id }) ?? (try? store.message(id: id)) else { return }
        let index = messages.firstIndex { $0.id == id } ?? 0
        do {
            try store.delete(ids: [id])
            removeFromList(id)
            let moved = try await graph?.move(id: id, to: destination)
            let title = destination == .archive ? "Arquivada" : "Apagada"
            pushUndo(title) { [weak self] in
                guard let self, let moved, let back = m.folder as String? else { return }
                var restored = m
                if let again = try? await graph?.move(id: moved.id, destinationID: back) { restored.id = again.id }
                try? store.upsert([restored])
                if selection == .account(.inbox) || selection == .local(m.localFolder ?? "") {
                    messages.insert(restored, at: min(index, messages.count))
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func snooze(_ id: String, until: Date) async {
        do {
            try store.setSnooze(id: id, until: until)
            removeFromList(id)
            pushUndo("Adiada até \(until.formatted(.dateTime.weekday(.abbreviated).hour().minute()))") { [weak self] in
                try? self?.store.setSnooze(id: id, until: nil)
                await self?.reloadList()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pushUndo(_ title: String, _ undo: @escaping @MainActor () async -> Void) {
        undoStack.append(UndoEntry(title: title, undo: undo))
        if undoStack.count > 20 { undoStack.removeFirst() }
        showToast("\(title) · desfazer (z)")
    }

    func undo() async {
        guard let entry = undoStack.popLast() else { showToast("Nada para desfazer"); return }
        await entry.undo()
        showToast("Desfeito: \(entry.title)")
    }

    func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { self?.toast = nil }
        }
    }
}

enum WebAuth {
    @MainActor
    static func run(url: URL, callbackScheme: String) async throws -> URL {
        let anchor = Anchor()
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { @Sendable callback, error in
                if let callback { continuation.resume(returning: callback) }
                else { continuation.resume(throwing: error ?? OAuthError.invalidCallback) }
            }
            session.presentationContextProvider = anchor
            session.prefersEphemeralWebBrowserSession = false
            session.start()
            withExtendedLifetime(anchor) {}
        }
    }

    private final class Anchor: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
            NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        }
    }
}
