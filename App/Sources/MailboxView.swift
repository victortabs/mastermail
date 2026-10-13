import MasterMailCore
import SwiftUI

struct MailboxView: View {
    @Environment(AppModel.self) private var model
    let account: String
    @State private var selection: StoredMessage.ID?

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            List(model.messages, selection: $selection) { message in
                MessageRow(message: message)
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 380)
            .overlay {
                if model.messages.isEmpty {
                    if model.isSyncing {
                        ContentUnavailableView("Indexando a Caixa de Entrada", systemImage: "arrow.triangle.2.circlepath", description: Text("\(model.syncProgress) mensagens"))
                    } else if !model.searchText.isEmpty {
                        ContentUnavailableView.search(text: model.searchText)
                    } else {
                        ContentUnavailableView("Caixa de entrada vazia", systemImage: "tray")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if model.isSyncing, !model.messages.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Sincronizando: \(model.syncProgress)").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
                }
            }
        } detail: {
            if model.openMessage != nil {
                ConversationView()
            } else {
                ContentUnavailableView("Nenhuma mensagem aberta", systemImage: "envelope.open")
            }
        }
        .searchable(text: $model.searchText, placement: .sidebar, prompt: "Buscar no Índice local")
        .navigationTitle(model.searchText.isEmpty ? "Caixa de entrada" : "Busca")
        .navigationSubtitle(account)
        .toolbar {
            ToolbarItem {
                Button { Task { await model.refresh() } } label: { Label("Atualizar", systemImage: "arrow.clockwise") }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .disabled(model.isSyncing)
            }
            ToolbarItem {
                Button("Sair") { Task { await model.signOut() } }
            }
        }
        .onChange(of: selection) { _, id in
            guard let id, let message = model.messages.first(where: { $0.id == id }) else { return }
            Task { await model.open(message) }
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
        }
        .padding(.vertical, 2)
    }
}
