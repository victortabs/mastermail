import MasterMailCore
import SwiftUI

/// Uma composição: rascunho no servidor desde o início, editor rich text com atalhos Markdown, assinatura automática.
@MainActor
@Observable
final class ComposeModel: Identifiable {
    enum Mode: Equatable {
        case new
        case reply(messageID: String, all: Bool)
        case forward(messageID: String)
        case resend(messageID: String)
    }

    let id = UUID()
    let mode: Mode
    private let graph: GraphClient
    private let signature: String
    private(set) var draft: Message?
    var to = ""
    var cc = ""
    var subject = ""
    var body = AttributedString("")
    private(set) var isBusy = true
    var error: String?
    private var originalParticipants: Set<String> = []
    var removedParticipants: [String] = []

    init(mode: Mode, graph: GraphClient, signature: String = "") {
        self.mode = mode
        self.graph = graph
        self.signature = signature
    }

    var title: String {
        switch mode {
        case .new: "Nova mensagem"
        case .reply(_, true): "Responder"
        case .reply(_, false): "Responder ao remetente"
        case .forward: "Encaminhar"
        case .resend: "Reenviar"
        }
    }

    private(set) var attachments: [String] = []
    /// Envio programado: o servidor segura até esta hora (requisito).
    var sendAt: Date?

    var hasContent: Bool { !String(body.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func start() async {
        do {
            let d: Message
            switch mode {
            case .new: d = try await graph.createDraft()
            case let .reply(id, all): d = try await graph.createReply(to: id, all: all)
            case let .forward(id): d = try await graph.createForward(of: id)
            case let .resend(id): d = try await graph.createResend(of: graph.message(id: id))
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

    private var currentRecipients: (to: [Recipient], cc: [Recipient]) { (Recipient.parseList(to), Recipient.parseList(cc)) }

    func checkRemovedParticipants() -> [String] {
        let now = Set((currentRecipients.to + currentRecipients.cc).compactMap { $0.emailAddress.address?.lowercased() })
        return originalParticipants.subtracting(now).sorted()
    }

    /// Assinatura: HTML colado nas Configurações, ou texto simples com quebras de linha.
    private var signatureHTML: String {
        let s = signature.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "" }
        let html = s.contains("<") ? s : s.htmlEscaped.replacingOccurrences(of: "\n", with: "<br>")
        return "<br><br><div class=\"mm-signature\">\(html)</div>"
    }

    /// Grava o rascunho e envia. Chamado depois dos 10 s de arrependimento.
    func send() async {
        guard let draft else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let quoted = draft.body?.contentType.lowercased() == "html" ? (draft.body?.content ?? "") : ""
            let html = RichText.html(from: body) + signatureHTML + "<br>" + quoted
            try await graph.updateDraft(id: draft.id, DraftPatch(
                subject: subject, toRecipients: currentRecipients.to, ccRecipients: currentRecipients.cc,
                body: ItemBody(contentType: "html", content: html), sendAt: sendAt
            ))
            try await graph.send(draftID: draft.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Anexa um arquivo ao rascunho (até 3 MB nesta rota).
    func attach(_ url: URL) async {
        guard let draft else { return }
        do {
            let data = try Data(contentsOf: url)
            guard data.count <= 3_000_000 else { error = "Anexo acima de 3 MB ainda não é suportado."; return }
            let type = UTTypeFor(url)
            try await graph.addAttachment(draftID: draft.id, name: url.lastPathComponent, contentType: type, data: data)
            attachments.append(url.lastPathComponent)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func UTTypeFor(_ url: URL) -> String {
        (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType?.preferredMIMEType) ?? "application/octet-stream"
    }

    func discard() async {
        guard let draft else { return }
        try? await graph.deleteDraft(id: draft.id)
    }
}

/// O editor, inline no fim da Conversa (responder/encaminhar) ou em sheet (nova mensagem).
struct ComposeEditor: View {
    @Environment(AppModel.self) private var app
    @Bindable var model: ComposeModel
    let inline: Bool
    @State private var confirmRemoved = false
    @State private var confirmDiscard = false
    @State private var showSubject = false
    @State private var scheduling = false
    @State private var scheduleDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)!
    private enum Field { case to, body }
    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.title).font(.headline)
                Spacer()
                if model.isBusy { ProgressView().controlSize(.small) }
            }
            Grid(alignment: .leading, verticalSpacing: 4) {
                GridRow { Text("Para").foregroundStyle(.secondary).gridColumnAlignment(.trailing); RecipientField(prompt: "", text: $model.to).focused($focus, equals: .to) }
                GridRow { Text("Cc").foregroundStyle(.secondary); RecipientField(prompt: "", text: $model.cc) }
                if model.mode == .new || showSubject {
                    GridRow { Text("Assunto").foregroundStyle(.secondary); TextField("", text: $model.subject) }
                } else {
                    GridRow { Text(""); Button(model.subject.isEmpty ? "(sem assunto)" : model.subject) { showSubject = true }.buttonStyle(.plain).foregroundStyle(.secondary).font(.caption) }
                }
            }
            .textFieldStyle(.roundedBorder)
            TextEditor(text: $model.body)
                .focused($focus, equals: .body)
                .font(.body)
                .frame(minHeight: inline ? 160 : 300)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .onChange(of: model.body) { _, _ in model.applyShortcuts() }
            if !model.attachments.isEmpty {
                HStack(spacing: 6) {
                    ForEach(model.attachments, id: \.self) { Label($0, systemImage: "paperclip").font(.caption) }
                }
            }
            HStack {
                Button { pickAttachment() } label: { Label("Anexar", systemImage: "paperclip") }.disabled(model.draft == nil)
                Text(model.mode == .new ? "Assinatura entra no fim." : "Assinatura e histórico citado entram abaixo do seu texto.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Descartar") { if model.hasContent { confirmDiscard = true } else { discard() } }
                    .keyboardShortcut(.escape, modifiers: [])
                Button(model.sendAt.map { "Enviar em \($0.formatted(.dateTime.day().month().hour().minute()))" } ?? "Enviar depois…") { scheduling = true }
                    .popover(isPresented: $scheduling) {
                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker("Enviar em", selection: $scheduleDate, in: Date()...)
                            HStack {
                                if model.sendAt != nil { Button("Enviar agora") { model.sendAt = nil; scheduling = false } }
                                Spacer()
                                Button("Programar") { model.sendAt = scheduleDate; scheduling = false }.keyboardShortcut(.defaultAction)
                            }
                            Text("O servidor segura a mensagem; pode fechar o app. Até lá ela fica em Rascunhos.").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding().frame(width: 320)
                    }
                if case let .reply(id, _) = model.mode {
                    Button("Enviar e arquivar") { trySend(thenArchive: id) }
                        .keyboardShortcut(.return, modifiers: [.command, .shift])
                        .disabled(model.isBusy || model.draft == nil)
                }
                Button("Enviar") { trySend() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy || model.draft == nil)
            }
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.4)))
        .frame(minWidth: inline ? nil : 640)
        .alert("Erro", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .alert("Você tirou gente da conversa", isPresented: $confirmRemoved) {
            Button("Enviar mesmo assim") { app.scheduleSend(model) }
            Button("Voltar", role: .cancel) {}
        } message: { Text("Não vão receber: " + model.removedParticipants.joined(separator: ", ")) }
        .alert("Descartar o rascunho?", isPresented: $confirmDiscard) {
            Button("Descartar", role: .destructive) { discard() }
            Button("Continuar escrevendo", role: .cancel) {}
        }
        // Responder e encaminhar começam no texto; mensagem nova começa no Para.
        .onChange(of: model.isBusy) { _, busy in if !busy { focus = model.mode == .new ? .to : .body } }
    }

    private func trySend(thenArchive: String? = nil) {
        model.removedParticipants = model.checkRemovedParticipants()
        if model.removedParticipants.isEmpty {
            app.scheduleSend(model)
            if let id = thenArchive { Task { await app.move(id, to: .archive) } }
        } else {
            confirmRemoved = true
        }
    }

    private func pickAttachment() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        Task { for url in panel.urls { await model.attach(url) } }
    }

    private func discard() {
        Task { await model.discard(); app.compose = nil }
    }
}
