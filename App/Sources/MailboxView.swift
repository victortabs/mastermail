import MasterMailCore
import SwiftUI

struct MailboxView: View {
    @Environment(AppModel.self) private var model
    let account: String
    @State private var selection: StoredMessage.ID?
    @FocusState private var searchFocused: Bool

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
        .navigationTitle(model.searchText.isEmpty ? (model.folder(model.selectedFolderID)?.displayName ?? "MasterMail") : "Busca")
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
        .onKeyPress(characters: .init(charactersIn: "jkeu#/")) { press in
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
            default: return .ignored
            }
            return .handled
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

    var body: some View {
        @Bindable var model = model
        List(model.folders, selection: $model.selectedFolderID) { folder in
            HStack {
                Image(systemName: icon(for: folder))
                Text(folder.displayName).lineLimit(1)
                Spacer()
                if folder.unreadItemCount > 0 {
                    Text("\(folder.unreadItemCount)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.leading, CGFloat(folder.depth) * 12)
        }
        .safeAreaInset(edge: .bottom) {
            if model.isSyncing {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(model.syncStatus.isEmpty ? "Sincronizando" : model.syncStatus).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .padding(6).frame(maxWidth: .infinity).background(.bar)
            }
        }
    }

    private func icon(for folder: MailFolder) -> String {
        switch folder.id {
        case model.wellKnown[.inbox]: "tray"
        case model.wellKnown[.sentitems]: "paperplane"
        case model.wellKnown[.drafts]: "doc"
        case model.wellKnown[.archive]: "archivebox"
        case model.wellKnown[.deleteditems]: "trash"
        case model.wellKnown[.junkemail]: "xmark.bin"
        default: "folder"
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
