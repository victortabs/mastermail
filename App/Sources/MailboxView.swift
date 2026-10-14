import MasterMailCore
import SwiftUI

struct MailboxView: View {
    @Environment(AppModel.self) private var model
    let account: String
    @State private var selection: StoredMessage.ID?
    @FocusState private var searchFocused: Bool
    @State private var pickingFolderFor: String?
    @State private var snoozingFor: String?
    @State private var showPalette = false
    @State private var showHelp = false
    @State private var explainingFor: String?

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            FolderList()
                .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        } content: {
            if model.selection == .outbox {
                OutboxList().navigationSplitViewColumnWidth(min: 300, ideal: 380)
            } else {
                MessageList(selection: $selection)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 380)
            }
        } detail: {
            if model.openMessage != nil {
                ConversationView()
            } else {
                ContentUnavailableView("Nenhuma mensagem aberta", systemImage: "envelope.open", description: Text("j / k navegam · Enter entra na conversa · ? mostra os atalhos"))
            }
        }
        .inspector(isPresented: $model.showAssistant) { AssistantPanel().inspectorColumnWidth(min: 280, ideal: 340) }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Buscar: texto, from:, to:, org:, has:anexo, after:, before:, in:")
        .searchFocused($searchFocused)
        .navigationTitle(model.searchText.isEmpty ? title : "Busca")
        .navigationSubtitle(account)
        .toolbar {
            ToolbarItem(placement: .navigation) { ViewPicker() }
            ToolbarItemGroup {
                Button { model.startCompose(.new) } label: { Label("Nova mensagem", systemImage: "square.and.pencil") }
                    .keyboardShortcut("n", modifiers: .command)
                Button { reply(all: true) } label: { Label("Responder", systemImage: "arrowshape.turn.up.left.2") }.disabled(targetID == nil)
                Button { reply(all: false) } label: { Label("Responder ao remetente", systemImage: "arrowshape.turn.up.left") }
                    .keyboardShortcut("r", modifiers: .command).disabled(targetID == nil)
                Button { if let id = targetID { model.startCompose(.forward(messageID: id)) } } label: { Label("Encaminhar", systemImage: "arrowshape.turn.up.right") }.disabled(targetID == nil)
            }
            ToolbarItemGroup {
                if model.aiEnabled {
                    Button { model.showAssistant.toggle() } label: { Label("Aba lateral", systemImage: "sparkles") }.keyboardShortcut("a", modifiers: [.command, .shift])
                }
                Button { showPalette = true } label: { Label("Paleta de comandos", systemImage: "command") }.keyboardShortcut("k", modifiers: .command)
                Button { Task { await model.refresh() } } label: { Label("Atualizar", systemImage: "arrow.clockwise") }.keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
        .overlay(alignment: .bottom) { ToastView() }
        .task(id: selection) {
            guard let id = selection, let message = model.messages.first(where: { $0.id == id }) else { return }
            await model.open(message)
        }
        .onChange(of: model.messages.map(\.id)) { old, new in
            guard let id = selection, !new.contains(id) else { return }
            if let index = old.firstIndex(of: id), !new.isEmpty { selection = new[min(index, new.count - 1)] }
            else { selection = nil }
        }
        .onChange(of: model.selection) { _, _ in selection = nil }
        .sheet(item: Binding(get: { model.compose?.mode == .new ? model.compose : nil }, set: { if $0 == nil { model.compose = nil } })) { compose in
            NavigationStack { ComposeEditor(model: compose, inline: false).interactiveDismissDisabled(compose.hasContent) }
        }
        .sheet(item: $pickingFolderFor) { _ in
            LocalFolderPicker { name in pickingFolderFor = nil; act { await model.moveToLocalFolder($0, name) } }
        }
        .sheet(item: $snoozingFor) { _ in
            SnoozePicker { date in snoozingFor = nil; act { await model.snooze($0, until: date) } }
        }
        .sheet(isPresented: $showPalette) { CommandPalette(commands: commands) }
        .sheet(isPresented: $showHelp) { ShortcutsHelp() }
        .sheet(isPresented: $model.showOrganizer) { OrganizerSheet() }
        .sheet(item: $explainingFor) { _ in
            ExplanationSheet { text in explainingFor = nil; act { await model.rejectNoise($0, explanation: text) } }
        }
        // Atalhos estilo Gmail (docs/04-ux.md). Teclas únicas valem fora de campos de texto.
        .onKeyPress(characters: .init(charactersIn: "jkeu#/vrfchszo?Oyn"), phases: .down) { press in
            if model.compose != nil || searchFocused || NSApplication.shared.keyWindow?.firstResponder is NSTextView { return .ignored }
            if !press.modifiers.intersection([.command, .control, .option]).isEmpty { return .ignored }
            if model.conversationFocused {
                switch press.characters {
                case "j": model.moveFocus(1)
                case "k": model.moveFocus(-1)
                case "o": if let id = model.focusedNodeID { Task { await model.toggle(id) } }
                case "O": Task { await model.expandAll() }
                default: return handleCommon(press.characters)
                }
                return .handled
            }
            switch press.characters {
            case "j": moveSelection(by: 1)
            case "k": moveSelection(by: -1)
            case "o": if let id = model.openMessage?.id { Task { await model.toggle(id) } }
            default: return handleCommon(press.characters)
            }
            return .handled
        }
        .onKeyPress(.return) {
            guard model.compose == nil, model.openMessage != nil, !model.conversationFocused else { return .ignored }
            model.conversationFocused = true
            return .handled
        }
        .onKeyPress(.escape) {
            if model.compose != nil { return .ignored }
            if model.conversationFocused { model.conversationFocused = false; return .handled }
            if !model.searchText.isEmpty { model.searchText = ""; return .handled }
            return .ignored
        }
    }

    private func handleCommon(_ key: String) -> KeyPress.Result {
        switch key {
        case "e": act { await model.move($0, to: .archive) }
        case "#": act { await model.move($0, to: .deleteditems) }
        case "u": act { id in
            let isRead = model.messages.first { $0.id == id }?.isRead ?? true
            await model.setRead(id, !isRead)
        }
        case "s": if let id = targetID { Task { await model.toggleFlag(id) } }
        case "/": searchFocused = true
        case "v": if targetID != nil { pickingFolderFor = targetID }
        case "h": if targetID != nil { snoozingFor = targetID }
        case "r": reply(all: true)
        case "f": if let id = targetID { model.startCompose(.forward(messageID: id)) }
        case "c": model.startCompose(.new)
        case "z": Task { await model.undo() }
        case "y": if model.selection == .triage { act { await model.confirmNoise($0) } } else { return .ignored }
        case "n": if model.selection == .triage, targetID != nil { explainingFor = targetID } else { return .ignored }
        case "?": showHelp = true
        default: return .ignored
        }
        return .handled
    }

    private func reply(all: Bool) {
        if let id = targetID { model.startCompose(.reply(messageID: id, all: all)) }
    }

    /// Mensagem alvo das ações: a focada na Conversa, senão a aberta, senão a selecionada.
    private var targetID: String? {
        (model.conversationFocused ? model.focusedNodeID : nil) ?? model.openMessage?.id ?? selection
    }

    private var title: String {
        switch model.selection {
        case .account(let known): FolderList.label(known)
        case .local(let name): name
        case .snoozed: "Adiadas"
        case .awaitingMe: "Sem resposta sua"
        case .awaitingThem: "Sem resposta deles"
        case .triage: "Triagem"
        case .noise: "Ruído"
        case .outbox: "Caixa de saída"
        case nil: "MasterMail"
        }
    }

    private func moveSelection(by delta: Int) {
        let ids = model.messages.map(\.id)
        guard !ids.isEmpty else { return }
        let current = selection.flatMap { ids.firstIndex(of: $0) } ?? -1
        selection = ids[min(max(current + delta, 0), ids.count - 1)]
    }

    /// Executa a ação sobre o alvo e avança para o próximo item (UX: Caixa de entrada é fila).
    private func act(_ action: @escaping (String) async -> Void) {
        guard let id = targetID else { return }
        let ids = model.messages.map(\.id)
        let index = ids.firstIndex(of: id) ?? 0
        Task {
            await action(id)
            let remaining = model.messages.map(\.id)
            if remaining.contains(id) { return }
            selection = remaining.isEmpty ? nil : remaining[min(index, remaining.count - 1)]
            model.conversationFocused = false
        }
    }

    private var commands: [PaletteCommand] {
        [
            .init("Responder (a todos)", "r") { reply(all: true) },
            .init("Responder ao remetente", "⌘R") { reply(all: false) },
            .init("Encaminhar", "f") { if let id = targetID { model.startCompose(.forward(messageID: id)) } },
            .init("Nova mensagem", "c") { model.startCompose(.new) },
            .init("Arquivar", "e") { act { await model.move($0, to: .archive) } },
            .init("Apagar", "#") { act { await model.move($0, to: .deleteditems) } },
            .init("Mover para pasta local", "v") { pickingFolderFor = targetID },
            .init("Adiar", "h") { snoozingFor = targetID },
            .init("Sinalizar", "s") { if let id = targetID { Task { await model.toggleFlag(id) } } },
            .init("Marcar lida / não lida", "u") { _ = handleCommon("u") },
            .init("Desfazer", "z") { Task { await model.undo() } },
            .init("Buscar", "/") { searchFocused = true },
            .init("Atualizar", "⌘⇧R") { Task { await model.refresh() } },
            .init("Calendário", "⌘2") { model.view = .calendar },
            .init("Enviar disponibilidade", "") {
                let m = targetID.flatMap { id in model.messages.first { $0.id == id } }
                model.availabilityRecipient = m.map { $0.fromName.isEmpty ? $0.fromAddress : "\($0.fromName) <\($0.fromAddress)>" } ?? ""
            },
            .init("Pessoas", "⌘3") { model.view = .people },
            .init("Atalhos", "?") { showHelp = true },
            .init("Aba lateral", "⌘⇧A") { model.showAssistant.toggle() },
            .init("Organizar a caixa (proposta de regras e pastas)", "") { model.showOrganizer = true },
            .init("Reenviar", "") { if let id = targetID { model.startCompose(.resend(messageID: id)) } },
            .init("Encaminhar como anexo", "") { if let id = targetID { model.startCompose(.forwardAsAttachment(messageID: id)) } },
        ].filter { model.aiEnabled || !["Aba lateral", "Organizar a caixa (proposta de regras e pastas)"].contains($0.name) }
    }
}

/// Mail / Calendário / Pessoas (⌘1 ⌘2 ⌘3).
struct ViewPicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Picker("Visão", selection: $model.view) {
            Image(systemName: "envelope").tag(AppModel.AppView.mail)
            Image(systemName: "calendar").tag(AppModel.AppView.calendar)
            Image(systemName: "person.2").tag(AppModel.AppView.people)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

/// Toast discreto no rodapé: "Arquivada · desfazer (z)".
struct ToastView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let toast = model.toast {
            HStack(spacing: 8) {
                Text(toast)
                if toast.contains("· desfazer (z)"), !model.undoStack.isEmpty {
                    Button("Desfazer") { Task { await model.undo() } }.buttonStyle(.plain).foregroundStyle(Color.accentColor)
                }
            }
                .font(.callout)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .shadow(radius: 4)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct FolderList: View {
    @Environment(AppModel.self) private var model
    @State private var newFolderName = ""
    @State private var creating = false
    @State private var renaming: String?
    @State private var renameTo = ""

    static func label(_ known: WellKnownFolder) -> String {
        switch known {
        case .inbox: "Caixa de entrada"
        case .sentitems: "Enviados"
        case .drafts: "Rascunhos"
        case .archive: "Arquivo"
        case .deleteditems: "Lixeira"
        case .junkemail: "Lixo eletrônico"
        }
    }

    static func icon(_ known: WellKnownFolder) -> String {
        switch known {
        case .inbox: "tray"
        case .sentitems: "paperplane"
        case .drafts: "doc"
        case .archive: "archivebox"
        case .deleteditems: "trash"
        case .junkemail: "xmark.bin"
        }
    }

    var body: some View {
        @Bindable var model = model
        List(selection: $model.selection) {
            Section("Conta") {
                ForEach(WellKnownFolder.allCases, id: \.self) { known in
                    HStack {
                        Label(Self.label(known), systemImage: Self.icon(known))
                        Spacer()
                        if known == .inbox, model.unreadCount(.inbox) > 0 {
                            Text("\(model.unreadCount(.inbox))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tag(AppModel.SidebarItem.account(known))
                }
            }
            if model.aiEnabled { Section("Triagem") {
                HStack {
                    Label("Triagem", systemImage: "tray.and.arrow.down")
                    Spacer()
                    if model.triageCount > 0 { Text("\(model.triageCount)").font(.caption).foregroundStyle(.secondary) }
                }
                .tag(AppModel.SidebarItem.triage)
                Label("Ruído", systemImage: "speaker.slash").tag(AppModel.SidebarItem.noise)
            } }
            if !model.failedSends.isEmpty {
                Section {
                    HStack {
                        Label("Caixa de saída", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                        Spacer()
                        Text("\(model.failedSends.count)").font(.caption).foregroundStyle(.red)
                    }
                    .tag(AppModel.SidebarItem.outbox)
                }
            }
            Section("Acompanhamento") {
                Label("Sem resposta sua", systemImage: "arrowshape.turn.up.left.circle").tag(AppModel.SidebarItem.awaitingMe)
                Label("Sem resposta deles", systemImage: "clock.arrow.circlepath").tag(AppModel.SidebarItem.awaitingThem)
                Label("Adiadas", systemImage: "zzz").tag(AppModel.SidebarItem.snoozed)
            }
            Section {
                ForEach(model.localFolders, id: \.self) { name in
                    Label(name, systemImage: "folder")
                        .tag(AppModel.SidebarItem.local(name))
                        .contextMenu { Button("Renomear…") { renameTo = name; renaming = name } }
                }
                if creating {
                    TextField("Nome da pasta", text: $newFolderName)
                        .onSubmit { model.createLocalFolder(newFolderName); newFolderName = ""; creating = false }
                        .onExitCommand { creating = false }
                }
            } header: {
                HStack {
                    Text("Pastas locais")
                    Spacer()
                    if model.aiEnabled { Button { model.showOrganizer = true } label: { Image(systemName: "wand.and.stars") }.buttonStyle(.plain).help("Organizar a caixa") }
                    Button { creating = true } label: { Image(systemName: "plus") }.buttonStyle(.plain)
                }
            }
        }
        .alert("Renomear pasta", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Nome", text: $renameTo)
            Button("Renomear") { if let old = renaming { Task { await model.renameLocalFolder(old, to: renameTo) } }; renaming = nil }
            Button("Cancelar", role: .cancel) { renaming = nil }
        }
        .safeAreaInset(edge: .bottom) {
            if let error = model.syncError ?? model.queueError {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Falha na sincronização", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                    Text(error).lineLimit(3).foregroundStyle(.secondary).help(error)
                    HStack {
                        Button("Tentar de novo") { Task { await model.refresh() } }
                        Button("Reconectar") { Task { await model.signIn() } }
                    }.controlSize(.mini)
                }.font(.caption).padding(6).frame(maxWidth: .infinity, alignment: .leading).background(.bar)
            } else if model.pendingSendCount > 0 {
                Label("\(model.pendingSendCount) envio(s) aguardando 10 s", systemImage: "paperplane").font(.caption).padding(6).frame(maxWidth: .infinity).background(.bar)
            } else if model.pendingCount > 0 {
                Label("\(model.pendingCount) ação(ões) aguardando conexão", systemImage: "wifi.slash").font(.caption2).foregroundStyle(.orange).padding(6).frame(maxWidth: .infinity).background(.bar)
            } else if !model.aiStatus.isEmpty {
                Text("IA: \(model.aiStatus)").font(.caption2).foregroundStyle(.secondary).lineLimit(2).padding(6).frame(maxWidth: .infinity).background(.bar)
            } else if model.isSyncing {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(model.syncStatus.isEmpty ? "Indexando" : "Indexando \(model.syncStatus)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .padding(6).frame(maxWidth: .infinity).background(.bar)
            }
        }
    }
}

/// Escolha de Pasta local pelo teclado (`v`): filtra, Enter escolhe; nome novo cria a pasta.
struct LocalFolderPicker: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let onPick: (String?) -> Void
    @State private var query = ""
    @FocusState private var focused: Bool

    private var matches: [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? model.localFolders : model.localFolders.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        VStack(spacing: 8) {
            TextField("Mover para a pasta local…", text: $query)
                .textFieldStyle(.roundedBorder).focused($focused)
                .onSubmit { onPick(matches.first ?? query.trimmingCharacters(in: .whitespaces)) }
                .onExitCommand { dismiss() }
            List {
                ForEach(matches, id: \.self) { name in Button(name) { onPick(name) }.buttonStyle(.plain) }
                if !query.trimmingCharacters(in: .whitespaces).isEmpty, !matches.contains(query.trimmingCharacters(in: .whitespaces)) {
                    Button("Criar \"\(query.trimmingCharacters(in: .whitespaces))\"") { onPick(query.trimmingCharacters(in: .whitespaces)) }.buttonStyle(.plain)
                }
                Button("Tirar da pasta local (volta à Caixa de entrada)") { onPick(nil) }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .frame(minHeight: 160)
        }
        .padding().frame(width: 360)
        .onAppear { focused = true }
    }
}

/// Adiar (`h`): opções fixas + data livre.
struct SnoozePicker: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (Date) -> Void
    @State private var custom = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

    private var options: [(String, Date)] {
        let cal = Calendar.current
        let now = Date()
        func at(_ date: Date, hour: Int) -> Date { cal.date(bySettingHour: hour, minute: 0, second: 0, of: date)! }
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
        var monday = now
        repeat { monday = cal.date(byAdding: .day, value: 1, to: monday)! } while cal.component(.weekday, from: monday) != 2
        return [
            ("Daqui a 3 horas", now.addingTimeInterval(3 * 3600)),
            ("Hoje à tarde, 14h", at(now, hour: 14)),
            ("Amanhã, 9h", at(tomorrow, hour: 9)),
            ("Segunda-feira, 9h", at(monday, hour: 9)),
        ].filter { $0.1 > now }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adiar até").font(.headline)
            ForEach(options, id: \.0) { label, date in
                Button(label) { onPick(date) }.buttonStyle(.plain)
            }
            Divider()
            DatePicker("Outra data", selection: $custom, in: Date()...)
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Adiar") { onPick(custom) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding().frame(width: 320)
    }
}

/// Envios que falharam: tentar de novo ou manter em Rascunhos. Nunca some em silêncio.
struct OutboxList: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List(model.failedSends) { f in
            VStack(alignment: .leading, spacing: 4) {
                Text(f.subject.isEmpty ? "(sem assunto)" : f.subject).fontWeight(.semibold)
                Text(f.error).font(.caption).foregroundStyle(.red).lineLimit(3)
                HStack {
                    Button("Tentar de novo") { Task { await model.retrySend(f) } }.disabled(f.compose.isBusy)
                    Button("Manter em Rascunhos") { model.discardFailed(f) }.disabled(f.compose.isBusy)
                }
                .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
        .overlay { if model.failedSends.isEmpty { ContentUnavailableView("Nada pendente", systemImage: "checkmark.circle") } }
    }
}

/// Próximos eventos de hoje, no topo da Lista.
struct TodayStrip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let events = model.calendar?.upcomingToday, !events.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(events.prefix(3)) { e in
                    HStack(spacing: 6) {
                        Text(e.isAllDay ? "dia todo" : e.start.formatted(date: .omitted, time: .shortened))
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 52, alignment: .leading)
                        Text(e.title).font(.caption).lineLimit(1)
                        if !e.isEditable { Image(systemName: "lock").font(.caption2).foregroundStyle(.tertiary) }
                    }
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
            .onTapGesture { model.view = .calendar }
        }
    }
}

struct MessageList: View {
    @Environment(AppModel.self) private var model
    @Binding var selection: StoredMessage.ID?

    var body: some View {
        List(model.messages, selection: $selection) { message in
            MessageRow(message: message)
                .onAppear { if message.id == model.messages.last?.id { Task { await model.loadMore() } } }
                .contextMenu {
                    Menu("Mover para pasta local") {
                        ForEach(model.localFolders, id: \.self) { name in
                            Button(name) { Task { await model.moveToLocalFolder(message.id, name) } }
                        }
                        if message.localFolder != nil {
                            Divider()
                            Button("Tirar da pasta local") { Task { await model.moveToLocalFolder(message.id, nil) } }
                        }
                    }
                    Button("Arquivar") { Task { await model.move(message.id, to: .archive) } }
                    Button(message.isFlagged ? "Tirar sinalizador" : "Sinalizar") { Task { await model.toggleFlag(message.id) } }
                    Button("Reenviar") { model.startCompose(.resend(messageID: message.id)) }
                    Button("Encaminhar como anexo") { model.startCompose(.forwardAsAttachment(messageID: message.id)) }
                    Button("Apagar", role: .destructive) { Task { await model.move(message.id, to: .deleteditems) } }
                }
        }
        .safeAreaInset(edge: .top, spacing: 0) { TodayStrip() }
        .overlay {
            if model.messages.isEmpty {
                if model.isSearching {
                    ProgressView("Buscando…")
                } else if !model.searchText.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                } else if model.isSyncing, model.selection == .account(.inbox) {
                    ContentUnavailableView("Indexando", systemImage: "arrow.triangle.2.circlepath", description: Text(model.syncStatus))
                } else {
                    ContentUnavailableView("Nada aqui", systemImage: "tray")
                }
            }
        }
    }
}

struct MessageRow: View {
    @Environment(AppModel.self) private var model
    let message: StoredMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(message.fromName.isEmpty ? message.fromAddress : message.fromName)
                    .fontWeight(message.isRead ? .regular : .bold).lineLimit(1)
                Spacer()
                if message.isFlagged { Image(systemName: "flag.fill").font(.caption).foregroundStyle(.orange) }
                if message.hasAttachments { Image(systemName: "paperclip").font(.caption).foregroundStyle(.secondary) }
                if let until = message.snoozedUntil, until > Date() {
                    Text(until, format: .dateTime.weekday(.abbreviated).hour().minute()).font(.caption).foregroundStyle(.purple)
                } else {
                    Text(message.receivedAt, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(message.subject.isEmpty ? "(sem assunto)" : message.subject)
                .lineLimit(1).fontWeight(message.isRead ? .regular : .semibold)
            Text(message.preview).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            HStack(spacing: 4) {
                if model.aiEnabled, message.importante { Badge("Importante", .red) }
                if model.aiEnabled, let tipo = message.tipo.flatMap(Tipo.init(rawValue:)), tipo != .pessoa { Badge(tipo.label, .gray) }
                if !message.categories.isEmpty { CategoryChips(categories: message.categories) }
            }
            // Justificativa (CONTEXT.md): a IA explica em uma linha; com a IA desligada a linha não existe.
            if model.aiEnabled, let why = message.justificativa, !why.isEmpty, (message.importante || Tipo(rawValue: message.tipo ?? "")?.isRuido == true) {
                Text(why).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

/// `n` na Triagem: por que isso não é ruído? Vira Regra.
struct ExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Por que isso não é ruído?").font(.headline)
            Text("Explique em uma frase. O MasterMail transforma em uma Regra para o remetente ou o domínio e nunca mais pergunta.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("ex.: é o aviso de pagamento do cliente, preciso ver", text: $text, axis: .vertical)
                .lineLimit(2 ... 4).textFieldStyle(.roundedBorder).focused($focused)
                .onSubmit { onSubmit(text) }
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Criar regra") { onSubmit(text) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding().frame(width: 420)
        .onAppear { focused = true }
    }
}

/// Etiquetas de Categoria. Cor estável derivada do nome (as cores reais do Outlook exigem MailboxSettings.Read).
struct CategoryChips: View {
    let categories: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(categories, id: \.self) { name in
                Text(name)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Self.color(for: name).opacity(0.18), in: Capsule())
                    .foregroundStyle(Self.color(for: name)).lineLimit(1)
            }
        }
    }

    static func color(for name: String) -> Color {
        let palette: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink, .brown]
        let hash = name.unicodeScalars.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1.value) }
        return palette[Int(UInt(bitPattern: hash) % UInt(palette.count))]
    }
}
