import MasterMailCore
import SwiftUI

struct MailboxView: View {
    @Environment(AppModel.self) private var model
    let account: String
    @State private var selection: Message.ID?

    var body: some View {
        NavigationSplitView {
            List(model.messages, selection: $selection) { message in
                MessageRow(message: message)
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 380)
            .overlay {
                if model.messages.isEmpty, !model.isLoading {
                    ContentUnavailableView("Caixa de entrada vazia", systemImage: "tray")
                }
            }
        } detail: {
            if let message = model.openMessage {
                MessageDetail(message: message)
            } else {
                ContentUnavailableView("Nenhuma mensagem aberta", systemImage: "envelope.open")
            }
        }
        .navigationTitle("Caixa de entrada")
        .navigationSubtitle(account)
        .toolbar {
            ToolbarItem {
                Button { Task { await model.refresh() } } label: { Label("Atualizar", systemImage: "arrow.clockwise") }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .disabled(model.isLoading)
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
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(message.from?.emailAddress.name ?? message.from?.emailAddress.address ?? "(sem remetente)")
                    .fontWeight(message.isRead ? .regular : .bold)
                    .lineLimit(1)
                Spacer()
                Text(message.receivedDateTime, format: .relative(presentation: .named))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(message.subject?.isEmpty == false ? message.subject! : "(sem assunto)")
                .lineLimit(1)
                .fontWeight(message.isRead ? .regular : .semibold)
            Text(message.bodyPreview ?? "")
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

struct MessageDetail: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.subject ?? "(sem assunto)").font(.title2.bold())
            HStack {
                Text(message.from?.emailAddress.name ?? "").fontWeight(.semibold)
                Text(message.from?.emailAddress.address ?? "").foregroundStyle(.secondary)
                Spacer()
                Text(message.receivedDateTime, format: .dateTime).foregroundStyle(.secondary)
            }
            .font(.callout)
            if let to = message.toRecipients, !to.isEmpty {
                Text("Para: " + to.map { $0.emailAddress.name ?? $0.emailAddress.address ?? "" }.joined(separator: ", "))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Divider()
            if let body = message.body {
                MessageBodyView(body: body)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}
