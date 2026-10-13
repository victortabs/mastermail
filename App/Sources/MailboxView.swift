import MasterMailCore
import SwiftUI

struct MailboxView: View {
    @Environment(AppModel.self) private var model
    let account: String
    @State private var selection: StoredMessage.ID?
    @FocusState private var searchFocused: Bool
    @State private var pickingFolderFor: String?

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            FolderList()
                .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        } content: {
            MessageList(selection: $selection)
                .navigationSplitViewColumnWidth(min: 300, ideal: 380)
        } detail: {
            if model.openMessage != nil {
                ConversationView()
            } else {
                ContentUnavailableView("Nenhuma mensagem aberta", systemImage: "envelope.open")
            }
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Buscar no Índice local")
        .searchFocused($searchFocused)
        .navigationTitle(model.searchText.isEmpty ? title : "Busca")
        .navigationSubtitle(account)
        .toolbar {
            ToolbarItem {
                Button { Task { await model.refresh() } } label: { Label("Atualizar", systemImage: "arrow.clockwise") }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            ToolbarItem {
                Button("Sair") { Task { await model.signOut() } }
            }
        }
        .onChange(of: selection) { _, id in
            guard let id, let message = model.messages.first(where: { $0.id == id }) else { return }
            Task { await model.open(message) }
        }
        // Atalhos estilo Gmail (requisito). Teclas únicas valem quando a lista tem o foco.
        .sheet(item: $pickingFolderFor) { id in
            LocalFolderPicker { name in
                pickingFolderFor = nil
                act { await model.moveToLocalFolder($0, name) }
            }
        }
        .onKeyPress(characters: .init(charactersIn: "jkeu#/v")) { press in
            switch press.characters {
            case "j": moveSelection(by: 1)
            case "k": moveSelection(by: -1)
            case "e": act { await model.move($0, to: .archive) }
            case "#": act { await model.move($0, to: .deleteditems) }
            case "u": act { id in
                let isRead = model.messages.first { $0.id == id }?.isRead ?? true
                await model.setRead(id, !isRead)
            }
            case "/": searchFocused = true
            case "v": if selection != nil { pickingFolderFor = selection }
            default: return .ignored
            }
            return .handled
        }
    }

    private var title: String {
        switch model.selection {
        case .account(let known): FolderList.label(known)
        case .local(let name): name
        case nil: "MasterMail"
        }
    }

    private func moveSelection(by delta: Int) {
        let ids = model.messages.map(\.id)
        guard !ids.isEmpty else { return }
        let current = selection.flatMap { ids.firstIndex(of: $0) } ?? -1
        let next = min(max(current + delta, 0), ids.count - 1)
        selection = ids[next]
    }

    private func act(_ action: @escaping (String) async -> Void) {
        guard let id = selection else { return }
        let ids = model.messages.map(\.id)
        let index = ids.firstIndex(of: id) ?? 0
        Task {
            await action(id)
            let remaining = model.messages.map(\.id)
            selection = remaining.isEmpty ? nil : remaining[min(index, remaining.count - 1)]
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
            Section {
                ForEach(model.localFolders, id: \.self) { name in
                    Label(name, systemImage: "folder")
                        .tag(AppModel.SidebarItem.local(name))
                        .contextMenu {
                            Button("Renomear…") { renameTo = name; renaming = name }
                        }
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
            if model.isSyncing {
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
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { onPick(matches.first ?? query.trimmingCharacters(in: .whitespaces)) }
                .onExitCommand { dismiss() }
            List {
                ForEach(matches, id: \.self) { name in
                    Button(name) { onPick(name) }.buttonStyle(.plain)
                }
                if !query.trimmingCharacters(in: .whitespaces).isEmpty, !matches.contains(query.trimmingCharacters(in: .whitespaces)) {
                    Button("Criar \"\(query.trimmingCharacters(in: .whitespaces))\"") { onPick(query.trimmingCharacters(in: .whitespaces)) }.buttonStyle(.plain)
                }
                Button("Tirar da pasta local (volta à Caixa de entrada)") { onPick(nil) }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .frame(minHeight: 160)
        }
        .padding()
        .frame(width: 360)
        .onAppear { focused = true }
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
                    Button("Apagar", role: .destructive) { Task { await model.move(message.id, to: .deleteditems) } }
                }
        }
        .overlay {
            if model.messages.isEmpty {
                if !model.searchText.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                } else if model.isSyncing {
                    ContentUnavailableView("Indexando", systemImage: "arrow.triangle.2.circlepath", description: Text(model.syncStatus))
                } else {
                    ContentUnavailableView("Pasta vazia", systemImage: "tray")
                }
            }
        }
    }
}

struct MessageRow: View {
    let message: StoredMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(message.fromName.isEmpty ? message.fromAddress : message.fromName)
                    .fontWeight(message.isRead ? .regular : .bold)
                    .lineLimit(1)
                Spacer()
                if message.hasAttachments { Image(systemName: "paperclip").font(.caption).foregroundStyle(.secondary) }
                Text(message.receivedAt, format: .relative(presentation: .named))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(message.subject.isEmpty ? "(sem assunto)" : message.subject)
                .lineLimit(1)
                .fontWeight(message.isRead ? .regular : .semibold)
            Text(message.preview)
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            if !message.categories.isEmpty { CategoryChips(categories: message.categories) }
        }
        .padding(.vertical, 2)
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
                    .foregroundStyle(Self.color(for: name))
                    .lineLimit(1)
            }
        }
    }

    static func color(for name: String) -> Color {
        let palette: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink, .brown]
        let hash = name.unicodeScalars.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }
}
