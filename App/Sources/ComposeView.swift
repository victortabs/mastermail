import MasterMailCore
import SwiftUI

/// Uma composição: rascunho no servidor desde o início (requisito), editor rich text com atalhos Markdown.
@MainActor
@Observable
final class ComposeModel: Identifiable {
    enum Mode: Equatable {
        case new
        case reply(messageID: String, all: Bool)
        case forward(messageID: String)
    }

    let id = UUID()
    let mode: Mode
    private let graph: GraphClient
    private(set) var draft: Message?
    var to = ""
    var cc = ""
    var subject = ""
    var body = AttributedString("")
    private(set) var isBusy = true
    private(set) var isSent = false
    var error: String?
    /// Quem estava na conversa quando o rascunho nasceu (para avisar se alguém for removido).
    private var originalParticipants: Set<String> = []
    var removedParticipants: [String] = []

    init(mode: Mode, graph: GraphClient) {
        self.mode = mode
        self.graph = graph
    }

    var title: String {
        switch mode {
        case .new: "Nova mensagem"
        case .reply(_, true): "Responder"
        case .reply(_, false): "Responder ao remetente"
        case .forward: "Encaminhar"
        }
    }

    func start() async {
        do {
            let d: Message
            switch mode {
            case .new: d = try await graph.createDraft()
            case let .reply(id, all): d = try await graph.createReply(to: id, all: all)
            case let .forward(id): d = try await graph.createForward(of: id)
            }
            draft = d
            to = (d.toRecipients ?? []).map(\.display).joined(separator: ", ")
            cc = (d.ccRecipients ?? []).map(\.display).joined(separator: ", ")
            subject = d.subject ?? ""
            originalParticipants = Set(((d.toRecipients ?? []) + (d.ccRecipients ?? [])).compactMap { $0.emailAddress.address?.lowercased() })
            isBusy = false
        } catch {
            self.error = error.localizedDescription
            isBusy = false
        }
    }

    func applyShortcuts() {
        var text = body
        var changed = false
        while RichText.applyMarkdownShortcuts(&text) { changed = true }
        if changed { body = text }
    }

    private var currentRecipients: (to: [Recipient], cc: [Recipient]) {
        (Recipient.parseList(to), Recipient.parseList(cc))
    }

    /// Antes de enviar: quem saiu da conversa? Vazio = pode enviar.
    func checkRemovedParticipants() -> [String] {
        let now = Set((currentRecipients.to + currentRecipients.cc).compactMap { $0.emailAddress.address?.lowercased() })
        return originalParticipants.subtracting(now).sorted()
    }

    func send() async {
        guard let draft else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            // Texto novo em cima; a citação do histórico que o servidor montou fica embaixo.
            let quoted = draft.body?.contentType.lowercased() == "html" ? (draft.body?.content ?? "") : ""
            let html = RichText.html(from: body) + "<br>" + quoted
            try await graph.updateDraft(id: draft.id, DraftPatch(
                subject: subject,
                toRecipients: currentRecipients.to,
                ccRecipients: currentRecipients.cc,
                body: ItemBody(contentType: "html", content: html)
            ))
            try await graph.send(draftID: draft.id)
            isSent = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func discard() async {
        guard let draft else { return }
        try? await graph.deleteDraft(id: draft.id)
    }
}

struct ComposeView: View {
    @Bindable var model: ComposeModel
    let onClose: () -> Void
    @State private var confirmRemoved = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Para", text: $model.to)
                TextField("Cc", text: $model.cc)
                TextField("Assunto", text: $model.subject)
            }
            .textFieldStyle(.plain)
            .formStyle(.columns)
            .padding(.horizontal)
            .padding(.top, 8)
            Divider().padding(.vertical, 6)
            TextEditor(text: $model.body)
                .font(.body)
                .padding(.horizontal, 8)
                .onChange(of: model.body) { _, _ in model.applyShortcuts() }
            if model.draft?.body != nil, model.mode != .new {
                Text("O histórico da conversa vai citado abaixo da sua resposta.")
                    .font(.caption).foregroundStyle(.secondary).padding(.bottom, 4)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .navigationTitle(model.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Descartar") { Task { await model.discard(); onClose() } }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enviar") { trySend() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(model.isBusy || model.draft == nil)
            }
        }
        .overlay { if model.isBusy { ProgressView().controlSize(.small).padding() } }
        .alert("Erro", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .alert("Você tirou gente da conversa", isPresented: $confirmRemoved) {
            Button("Enviar mesmo assim") { Task { await send() } }
            Button("Voltar", role: .cancel) {}
        } message: {
            Text("Não vão receber: " + model.removedParticipants.joined(separator: ", "))
        }
        .onChange(of: model.isSent) { _, sent in if sent { onClose() } }
    }

    private func trySend() {
        model.removedParticipants = model.checkRemovedParticipants()
        if model.removedParticipants.isEmpty { Task { await send() } } else { confirmRemoved = true }
    }

    private func send() async { await model.send() }
}
