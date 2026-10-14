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
        case restoringSession
        case sessionUnavailable
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
        case outbox
    }

    /// Envio que falhou: fica visível até ser reenviado ou descartado (requisito: falha de envio ruidosa).
    struct FailedSend: Identifiable {
        let id = UUID()
        let subject: String
        let error: String
        let compose: ComposeModel
        var archiveAfterSend: String? = nil
    }

    /// Uma ação que pode ser desfeita com `z`.
    struct UndoEntry {
        let id = UUID()
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
    private(set) var syncError: String?
    private(set) var queueError: String?
    private(set) var aiEnabled: Bool = true

    func updateAISettings(_ settings: AISettings) {
        do {
            try aiSettings.save(settings)
            aiEnabled = settings.localEnabled || settings.cloudEnabled
            if !aiEnabled {
                showAssistant = false; showOrganizer = false; aiStatus = ""
                if selection == .triage || selection == .noise { selection = .account(.inbox) }
            }
            Task { await reloadList() }
        } catch { errorMessage = error.localizedDescription }
    }
    private var searchTask: Task<Void, Never>?
    private var listRevision = UUID()
    private(set) var isSearching = false
    private var isLoadingMore = false
    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            listRevision = UUID()
            searchTask?.cancel()
            searchTask = Task { [weak self] in
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                await self?.reloadList()
            }
        }
    }
    var errorMessage: String?
    /// O tenant pediu aprovação do administrador: URL de consentimento para mandar ao TI.
    var adminConsentURL: URL?

    /// Composição em curso. Responder/encaminhar aparecem inline na Conversa; nova mensagem em sheet.
    var compose: ComposeModel?
    private var pendingSends: [UUID: Task<Void, Never>] = [:]
    private(set) var pendingSendCount = 0

    private(set) var undoStack: [UndoEntry] = []
    private(set) var toast: String?
    private var toastTask: Task<Void, Never>?

    private var accountGeneration = UUID()
    private var graph: GraphClient?
    var client: GraphClient? { graph }
    /// IA (ADR 0004): Regra → modelo local → nuvem opt-in. Roda depois de cada sincronização da Caixa de entrada.
    let aiSettings: AISettingsStore
    private(set) var pipeline: ClassificationPipeline?
    private(set) var triageCount = 0
    let assistant = AssistantModel()
    var showAssistant = false
    private let mac = MacCalendar()
    private(set) var failedSends: [FailedSend] = []
    /// Fila offline (requisito): escritas no servidor que falharam por rede, repetidas a cada ciclo.
    private let queue: ActionQueue
    private(set) var pendingCount = 0
    let planStore = OrganizationPlanStore.default()
    var showOrganizer = false
    /// Remetentes (endereço ou domínio) cujas imagens remotas o usuário liberou de vez.
    var trustedImageSenders: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "trustedImageSenders") ?? [])
    private(set) var aiStatus = ""
    private var notified: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "notifiedIDs") ?? [])
    private var sync: MailSync?
    private let tokenStore = TokenStore.default()
    let store: MailStore
    private var pollTask: Task<Void, Never>?
    private var backfillTask: Task<Void, Never>?
    private var sessionRetryTask: Task<Void, Never>?
    private static let pageSize = 300

    static let redirectScheme = "msauth.\(Bundle.main.bundleIdentifier ?? "io.github.victortabs.mastermail")"
    static let clientIDDefaultsKey = "MasterMailClientID"

    init(store: MailStore? = nil, aiSettings: AISettingsStore = .default(), queue: ActionQueue = .default(), client: GraphClient? = nil, configureAutomatically: Bool = true) {
        self.aiSettings = aiSettings
        self.queue = queue
        self.graph = client
        do {
            if let store { self.store = store }
            else { self.store = try MailStore(path: MailStore.defaultPath()) }
        } catch {
            fatalError("Não abriu o Índice local: \(error)")
        }
        let settings = aiSettings.load()
        aiEnabled = settings.localEnabled || settings.cloudEnabled
        if configureAutomatically, let id = Self.storedClientID { configure(clientID: id) }
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
        sessionRetryTask?.cancel()
        accountGeneration = UUID()
        let config = OAuthConfig(clientID: clientID, redirectURI: "\(Self.redirectScheme)://auth")
        let client = GraphClient(config: config, store: tokenStore)
        graph = client
        sync = MailSync(graph: client, store: store, queue: queue)
        calendar = CalendarModel(graph: client)
        pipeline = ClassificationPipeline(store: store, settings: aiSettings)
        phase = .restoringSession
        let generation = accountGeneration
        Task {
            let hasSession = await client.isSignedIn
            guard generation == accountGeneration else { return }
            if hasSession { await restoreSession() }
            else { phase = .signedOut }
        }
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
            await restoreSession()
        } catch ASWebAuthenticationSessionError.canceledLogin {
        } catch let error as OAuthError where error.needsAdminConsent {
            adminConsentURL = OAuth.adminConsentURL(config: config)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        accountGeneration = UUID()
        sessionRetryTask?.cancel()
        sessionRetryTask = nil
        pollTask?.cancel()
        backfillTask?.cancel()
        searchTask?.cancel()
        listRevision = UUID()
        for task in pendingSends.values { task.cancel() }
        pendingSends = [:]
        pendingSendCount = 0
        compose = nil
        undoStack = []
        failedSends = []
        await graph?.signOut()
        messages = []
        folders = []
        openMessage = nil
        conversation = []
        wellKnown = [:]
        localFolders = []
        accountEmail = ""
        searchText = ""
        showAssistant = false
        NSApplication.shared.dockTile.badgeLabel = nil
        phase = .signedOut
    }

    func restoreSession() async {
        guard let graph else { return }
        sessionRetryTask?.cancel()
        sessionRetryTask = nil
        phase = .restoringSession
        let generation = accountGeneration
        do {
            let me = try await graph.me()
            guard accountGeneration == generation else { return }
            accountEmail = (me.mail ?? me.userPrincipalName ?? "").lowercased()
            guard let identifier = me.id ?? (accountEmail.isEmpty ? nil : accountEmail) else { throw GraphError.notSignedIn }
            do { try store.claimAccount(identifier: identifier, displayName: accountEmail.isEmpty ? identifier : accountEmail) }
            catch { await graph.signOut(); throw error }
            phase = .signedIn(account: accountEmail.isEmpty ? "conta" : accountEmail)
            await loadFolders()
            guard accountGeneration == generation else { return }
            reloadLocalFolders()
            pendingCount = await queue.count
            await folderChanged()
            guard accountGeneration == generation else { return }
            refreshCounters()
            startPolling()
            startBackfill()
            Task { await reconcileLocalFolders() }
            Task { await calendar?.load(requestMacAccess: false) }
        } catch {
            guard accountGeneration == generation else { return }
            let hasSession = await graph.isSignedIn
            guard accountGeneration == generation else { return }
            if hasSession {
                phase = .sessionUnavailable
                // Falta de rede não é logout. Tenta novamente sem abrir o login Microsoft.
                sessionRetryTask = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(30)) } catch { return }
                    guard let self, self.accountGeneration == generation else { return }
                    self.sessionRetryTask = nil
                    await self.restoreSession()
                }
            } else {
                errorMessage = error.localizedDescription
                phase = .signedOut
            }
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
        let generation = accountGeneration
        do {
            let assignments = try await graph.localFolderAssignments()
            guard accountGeneration == generation else { return }
            try store.applyLocalFolders(assignments, preserving: await queue.localFolderIDs)
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
            try await queue.enqueue(ids.map { .localFolder(id: $0, name: trimmed) })
            pendingCount = await queue.count
            Task { await drainQueue() }
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
            await server(.localFolder(id: id, name: name))
            pushUndo(name.map { "Movida para \($0)" } ?? "Tirada da pasta local") { [weak self] in
                guard let self else { return }
                try? store.setLocalFolder(id: id, old)
                await server(.localFolder(id: id, name: old))
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
                await drainQueue()
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
        await drainQueue()
        if let id = selectedFolderID ?? wellKnown[.inbox] { await syncFolder(id) }
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
            syncError = nil
            if id == selectedFolderID { await reloadList() }
            if id == wellKnown[.inbox] { await classifyInbox() }
        } catch {
            if !Task.isCancelled { syncError = error.localizedDescription }
        }
    }

    // MARK: IA (Tipo, Importante, Triagem, Regras)

    private func classifyInbox() async {
        guard aiEnabled else { return }
        guard let pipeline, let inbox = wellKnown[.inbox] else { return }
        let done = await pipeline.run(folder: inbox, max: 30)
        guard aiEnabled else { return }
        aiStatus = await pipeline.lastError ?? ""
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
        guard let important = try? store.importantUnread(limit: 20), !important.isEmpty else { return }
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
                await server(.categories(id: id, categories: categories))
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
        case .account(.inbox): try wellKnown[.inbox].map {
            try aiEnabled ? store.inboxMessages(folder: $0, limit: Self.pageSize, offset: offset) : store.messages(in: $0, limit: Self.pageSize, offset: offset)
        } ?? []
        case .account: try selectedFolderID.map { try store.messages(in: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .triage: try wellKnown[.inbox].map { try store.triage(folder: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .noise: try wellKnown[.inbox].map { try store.noise(folder: $0, limit: Self.pageSize, offset: offset) } ?? []
        case .outbox: []
        case .snoozed: offset == 0 ? try store.snoozed() : []
        case .awaitingMe: offset == 0 ? try store.awaitingMyReply(inbox: wellKnown[.inbox] ?? "", me: accountEmail) : []
        case .awaitingThem: offset == 0 ? try store.awaitingTheirReply(sent: wellKnown[.sentitems] ?? "", me: accountEmail) : []
        case nil: []
        }
    }

    func reloadList() async {
        let revision = UUID()
        listRevision = revision
        let queryText = searchText
        let selected = selection
        isSearching = !queryText.isEmpty
        defer { if listRevision == revision { isSearching = false } }
        do {
            if queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages = try page(offset: 0)
                hasMore = messages.count == Self.pageSize
            } else {
                let q = SearchQuery.parse(queryText)
                let store = store
                var results = try await Task.detached(priority: .userInitiated) { try store.search(q) }.value
                guard listRevision == revision, selection == selected, !Task.isCancelled else { return }
                messages = results
                hasMore = false
                // O servidor só complementa buscas simples: não pode ignorar os operadores locais.
                if let inbox = wellKnown[.inbox], !(try store.isFullyIndexed(folder: inbox)), !q.hasOperators, !q.text.isEmpty, let graph {
                    let seen = Set(results.map(\.id))
                    if let remote = try? await graph.searchServer(q.text) {
                        guard listRevision == revision, selection == selected, !Task.isCancelled else { return }
                        results += remote.filter { !seen.contains($0.id) }.map { StoredMessage(message: $0, folder: $0.parentFolderId ?? inbox) }
                        messages = results
                    }
                }
            }
        } catch {
            if listRevision == revision, !Task.isCancelled { errorMessage = error.localizedDescription }
        }
    }

    func loadMore() async {
        guard hasMore, searchText.isEmpty, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try page(offset: messages.count)
            let seen = Set(messages.map(\.id))
            messages += page.filter { !seen.contains($0.id) }
            hasMore = page.count == Self.pageSize
        } catch { errorMessage = error.localizedDescription }
    }

    /// Resultado de uma busca da Aba lateral substitui a lista.
    func showResults(_ results: [StoredMessage]) {
        searchTask?.cancel()
        listRevision = UUID()
        isSearching = false
        messages = results
        hasMore = false
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
            if !message.isRead { await setRead(message.id, true) }
            guard openMessage?.id == message.id, !Task.isCancelled else { return }
            await prepareBody(id: message.id)
            guard openMessage?.id == message.id, !Task.isCancelled else { return }
            if newest != message.id { await prepareBody(id: newest) }
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
            try Task.checkCancellation()
            // Atualiza apenas o corpo: um delta/ação pode ter alterado o restante durante o download.
            try store.cacheBody(id: id, html: m.bodyHTML)
            if let current = conversation.firstIndex(where: { $0.id == id }) {
                conversation[current].message.bodyHTML = m.bodyHTML
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Composição

    func startCompose(_ mode: ComposeModel.Mode) {
        if compose != nil { showToast("Conclua ou descarte o rascunho aberto antes de começar outro."); return }
        guard let graph else { return }
        let signature = UserDefaults.standard.string(forKey: "signatureHTML") ?? ""
        let model = ComposeModel(mode: mode, graph: graph, signature: signature)
        compose = model
        Task { await model.start() }
    }

    /// Cada envio tem seu próprio timer. O rascunho é salvo antes de fechar o editor.
    func scheduleSend(_ model: ComposeModel, thenArchive: String? = nil, delay: Duration = .seconds(10)) async {
        guard pendingSends[model.id] == nil, await model.prepareForSend() else { return }
        if compose?.id == model.id { compose = nil }
        let undoID = pushUndo("Enviando em 10 s") { [weak self] in
            guard let self, let task = pendingSends.removeValue(forKey: model.id) else { return }
            task.cancel()
            pendingSendCount = pendingSends.count
            showToast("Envio cancelado. O rascunho está salvo em Rascunhos.")
        }
        pendingSends[model.id] = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            guard let self, !Task.isCancelled else { return }
            // Depois que começou a chamada ao servidor, já não é possível desfazer o envio.
            undoStack.removeAll { $0.id == undoID }
            await model.send()
            pendingSends.removeValue(forKey: model.id)
            pendingSendCount = pendingSends.count
            if let error = model.error {
                failedSends.append(FailedSend(subject: model.subject, error: error, compose: model, archiveAfterSend: thenArchive))
                errorMessage = "Falha ao enviar \"\(model.subject)\": \(error)\nA mensagem está na Caixa de saída para tentar de novo."
                NSApplication.shared.requestUserAttention(.criticalRequest)
            } else {
                if let id = thenArchive { await move(id, to: .archive) }
                showToast("Enviada")
            }
        }
        pendingSendCount = pendingSends.count
    }

    // MARK: Organizador (proposta → Sugestão → aplicar)

    /// Gera uma proposta nova com o modelo pesado (Haiku via OpenRouter). Exige nuvem ligada.
    func generatePlan() async throws -> OrganizationPlan {
        let settings = aiSettings.load()
        guard settings.cloudEnabled, !settings.openRouterKey.isEmpty else {
            throw AIError.unavailable("Ligue a nuvem e informe a chave da OpenRouter em ⌘, → IA.")
        }
        guard let inbox = wellKnown[.inbox] else { throw AIError.unavailable("Caixa de entrada ainda não carregada.") }
        let profile = try store.profile(inbox: inbox, sent: wellKnown[.sentitems])
        let organizer = Organizer(provider: OpenRouterProvider(key: settings.openRouterKey, model: settings.openRouterHeavyModel))
        let plan = try await organizer.propose(from: profile)
        try planStore.save(plan)
        return plan
    }

    /// Aplica o que foi aceito: regras automáticas + pastas; classifica o índice na hora e manda as pastas ao servidor pela fila.
    func applyPlan(_ plan: OrganizationPlan, moveExisting: Bool) async {
        do {
            let moved = try store.apply(plan, moveExisting: moveExisting, automatic: true)
            reloadLocalFolders()
            refreshCounters()
            await reloadList()
            try await queue.enqueue(moved.map { .localFolder(id: $0.0, name: $0.1) })
            pendingCount = await queue.count
            showToast("\(plan.rules.count) regras e \(plan.folders.count) pastas aplicadas; \(moved.count) mensagens indo para as pastas no servidor")
            Task { await drainQueue() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Tarefas e eventos a partir da mensagem

    func createReminder(from m: StoredMessage, due: Date?) async {
        guard await mac.requestRemindersAccess() else { errorMessage = "Sem acesso ao Lembretes. Libere em Ajustes do Sistema → Privacidade → Lembretes."; return }
        do {
            try mac.createReminder(title: m.subject.isEmpty ? "E-mail de \(m.fromName)" : m.subject, notes: "De \(m.fromName) <\(m.fromAddress)>\n\n\(m.preview)", due: due)
            showToast("Lembrete criado")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Cancelar inscrição em um clique: mailto envia um e-mail vazio; https abre no navegador.
    func unsubscribe(_ m: StoredMessage) async {
        guard let graph else { return }
        do {
            let targets = try await graph.unsubscribeTargets(messageID: m.id)
            if let mailto = targets.first(where: { $0.scheme == "mailto" }) {
                let address = mailto.absoluteString.replacingOccurrences(of: "mailto:", with: "").split(separator: "?").first.map(String.init) ?? ""
                let draft = try await graph.createDraft()
                try await graph.updateDraft(id: draft.id, DraftPatch(subject: "unsubscribe", toRecipients: [Recipient(parsing: address)], body: ItemBody(contentType: "text", content: "unsubscribe")))
                try await graph.send(draftID: draft.id)
                showToast("Pedido de cancelamento enviado para \(address)")
            } else if let link = targets.first(where: { $0.scheme == "https" || $0.scheme == "http" }) {
                NSWorkspace.shared.open(link)
                showToast("Página de cancelamento aberta no navegador")
            } else {
                showToast("Esta mensagem não tem link de cancelamento")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retrySend(_ failed: FailedSend) async {
        guard !failed.compose.isBusy else { return }
        await failed.compose.send()
        if let error = failed.compose.error {
            errorMessage = error
        } else {
            failedSends.removeAll { $0.id == failed.id }
            if let id = failed.archiveAfterSend { await move(id, to: .archive) }
            showToast("Enviada")
        }
    }

    func discardFailed(_ failed: FailedSend) {
        failedSends.removeAll { $0.id == failed.id }
        showToast("Mantida em Rascunhos")
    }

    func trustImages(from m: StoredMessage, wholeDomain: Bool) {
        let key = wholeDomain ? (m.fromAddress.split(separator: "@").last.map(String.init) ?? m.fromAddress) : m.fromAddress
        trustedImageSenders.insert(key.lowercased())
        UserDefaults.standard.set(Array(trustedImageSenders), forKey: "trustedImageSenders")
    }

    func imagesAllowed(_ m: StoredMessage) -> Bool {
        let domain = m.fromAddress.split(separator: "@").last.map(String.init)?.lowercased() ?? ""
        return remoteImagesAllowed.contains(m.id) || trustedImageSenders.contains(m.fromAddress.lowercased()) || trustedImageSenders.contains(domain)
    }

    /// A fila é persistida antes da tentativa e conserva a ordem das ações, inclusive do desfazer.
    private func server(_ action: PendingAction) async {
        do {
            try await queue.enqueue(action)
            pendingCount = await queue.count
            await drainQueue()
        } catch { errorMessage = "Não foi possível guardar a ação: \(error.localizedDescription)" }
    }

    func drainQueue() async {
        guard let graph, await queue.count > 0 else { return }
        let done = await queue.drain(using: graph)
        pendingCount = await queue.count
        queueError = await queue.lastError
        if queueError == nil, done > 0 { showToast("\(done) ação(ões) pendente(s) enviada(s)") }
    }

    // MARK: Ações (local primeiro, servidor depois, todas com desfazer)

    func setRead(_ id: String, _ isRead: Bool) async {
        do {
            try store.setRead(id: id, isRead)
            if let i = messages.firstIndex(where: { $0.id == id }) { messages[i].isRead = isRead }
            if openMessage?.id == id { openMessage?.isRead = isRead }
            if let i = conversation.firstIndex(where: { $0.id == id }) { conversation[i].message.isRead = isRead }
            await server(.markRead(id: id, isRead: isRead))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFlag(_ id: String) async {
        guard let m = messages.first(where: { $0.id == id }) ?? (try? store.message(id: id)) else { return }
        let flagged = !m.isFlagged
        do {
            try store.setFlagged(id: id, flagged)
            if let i = messages.firstIndex(where: { $0.id == id }) { messages[i].isFlagged = flagged }
            if openMessage?.id == id { openMessage?.isFlagged = flagged }
            if let i = conversation.firstIndex(where: { $0.id == id }) { conversation[i].message.isFlagged = flagged }
            await server(.flag(id: id, flagged: flagged))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Arquivar e Apagar são ações de servidor (CONTEXT.md). Some da lista na hora; desfazer traz de volta.
    func move(_ id: String, to destination: WellKnownFolder) async {
        guard let graph, let m = messages.first(where: { $0.id == id }) ?? (try? store.message(id: id)) else { return }
        do {
            // Resolve escritas anteriores antes de uma operação que pode trocar o id da mensagem.
            await drainQueue()
            guard !(await queue.pendingActions).contains(where: { $0.messageID == id }) else {
                errorMessage = "Há ações aguardando conexão. Tente arquivar ou apagar quando elas forem sincronizadas."
                return
            }
            removeFromList(id)
            let moved: Message
            do { moved = try await graph.move(id: id, to: destination) }
            catch { await reloadList(); throw error }
            var stored = m
            stored.id = moved.id
            stored.folder = moved.parentFolderId ?? wellKnown[destination] ?? destination.rawValue
            try store.replace(id: id, with: stored)
            refreshCounters()
            let title = destination == .archive ? "Arquivada" : "Apagada"
            pushUndo(title) { [weak self] in
                guard let self else { return }
                do {
                    let again = try await graph.move(id: moved.id, destinationID: m.folder)
                    var restored = m
                    restored.id = again.id
                    try store.replace(id: moved.id, with: restored)
                    refreshCounters()
                    await reloadList()
                } catch { errorMessage = error.localizedDescription }
            }
        } catch { errorMessage = error.localizedDescription }
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

    @discardableResult
    func pushUndo(_ title: String, _ undo: @escaping @MainActor () async -> Void) -> UUID {
        let entry = UndoEntry(title: title, undo: undo)
        undoStack.append(entry)
        if undoStack.count > 20 { undoStack.removeFirst() }
        showToast("\(title) · desfazer (z)")
        return entry.id
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
    /// A API pode chamar de uma fila XPC. A closure de entrada não pode herdar MainActor.
    nonisolated static func completionHandler(
        onComplete: @escaping @MainActor @Sendable (Result<URL, any Error>) -> Void
    ) -> @Sendable (URL?, (any Error)?) -> Void {
        { @Sendable callback, error in
            let result: Result<URL, any Error>
            if let callback { result = .success(callback) }
            else { result = .failure(error ?? OAuthError.invalidCallback) }
            Task { @MainActor in onComplete(result) }
        }
    }

    @MainActor
    static func run(url: URL, callbackScheme: String) async throws -> URL {
        let context = SessionContext()
        return try await context.run(url: url, callbackScheme: callbackScheme)
    }

    /// Retém a sessão e sua janela até o callback; o provider da API é uma referência fraca.
    @MainActor
    private final class SessionContext: NSObject, ASWebAuthenticationPresentationContextProviding {
        private var session: ASWebAuthenticationSession?
        private var continuation: CheckedContinuation<URL, any Error>?

        private func finish(_ result: Result<URL, any Error>) {
            guard let continuation else { return }
            self.continuation = nil
            session = nil
            continuation.resume(with: result)
        }

        func run(url: URL, callbackScheme: String) async throws -> URL {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme,
                                                        completionHandler: WebAuth.completionHandler { [self] result in
                    finish(result)
                })
                self.session = session
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                if !session.start() {
                    finish(.failure(OAuthError.invalidCallback))
                }
            }
        }

        func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
            NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        }
    }
}
