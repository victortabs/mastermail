import MasterMailCore
import SwiftUI

/// Aba lateral (CONTEXT.md): conversa com a IA sobre o Contexto atual. Toda ação vira Sugestão: lista o que vai fazer e espera `y`.
@MainActor
@Observable
final class AssistantModel {
    struct Entry: Identifiable {
        let id = UUID()
        let fromUser: Bool
        var text: String
    }

    private(set) var log: [Entry] = []
    var input = ""
    private(set) var isBusy = false
    /// Ação proposta à espera de confirmação.
    private(set) var pending: (description: String, run: @MainActor () async -> Void)?
    private(set) var lastSearchIDs: [String] = []

    func say(_ text: String, fromUser: Bool = false) { log.append(Entry(fromUser: fromUser, text: text)) }

    func propose(_ description: String, run: @escaping @MainActor () async -> Void) {
        pending = (description, run)
        say(description + "  (y confirma · n cancela)")
    }

    func confirm() async {
        guard let p = pending else { return }
        pending = nil
        isBusy = true
        await p.run()
        isBusy = false
    }

    func cancel() {
        if pending != nil { pending = nil; say("Cancelado.") }
    }

    func setBusy(_ b: Bool) { isBusy = b }
    func setLastSearch(_ ids: [String]) { lastSearchIDs = ids }
}

extension AppModel {
    /// Descrição do Contexto (CONTEXT.md) para o modelo e para o usuário.
    var contextDescription: String {
        if !conversation.isEmpty { return "uma conversa com \(conversation.count) mensagens, assunto \"\(openMessage?.subject ?? "")\"" }
        if let m = openMessage { return "uma mensagem de \(m.fromName) sobre \"\(m.subject)\"" }
        return "nenhuma mensagem selecionada"
    }

    func ask(_ text: String) async {
        let request = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !request.isEmpty else { return }
        assistant.say(request, fromUser: true)
        assistant.input = ""
        guard let provider = await pipeline?.provider() else {
            assistant.say("A IA está desligada ou indisponível. Ligue o modelo local ou a nuvem em ⌘, → IA.")
            return
        }
        let ai = Assistant(provider: provider)
        assistant.setBusy(true)
        defer { assistant.setBusy(false) }
        do {
            let reply = try await ai.interpret(request, contextDescription: contextDescription)
            switch reply.action {
            case let .search(query, from, after, before):
                var q = SearchQuery.parse(query)
                q.from = from ?? q.from
                q.after = after ?? q.after
                q.before = before ?? q.before
                let results = try store.search(q, limit: 100)
                assistant.setLastSearch(results.map(\.id))
                showResults(results)
                assistant.say(results.isEmpty ? "Não achei nada para \"\(query)\"." : "\(results.count) mensagens na lista à esquerda. \(reply.say)")
            case let .move(folder):
                let ids = assistant.lastSearchIDs.isEmpty ? [openMessage?.id].compactMap { $0 } : assistant.lastSearchIDs
                guard !ids.isEmpty, !folder.isEmpty else { assistant.say("Não sei quais mensagens mover. Busque primeiro ou abra uma."); return }
                assistant.propose("Mover \(ids.count) mensagem(ns) para a Pasta local \"\(folder)\"?") { [weak self] in
                    for id in ids { await self?.moveToLocalFolder(id, folder) }
                    self?.assistant.say("Movidas \(ids.count) para \"\(folder)\".")
                }
            case .summary:
                guard !conversation.isEmpty else { assistant.say("Abra uma conversa para eu resumir."); return }
                let summary = try await ai.summarize(conversation.map(\.message))
                assistant.say("Resumo (gerado por IA):\n" + summary)
            case .draft:
                guard let target = openMessage else { assistant.say("Abra a mensagem que quer responder."); return }
                let text = try await ai.draft(instruction: request, conversation: conversation.map(\.message), me: accountEmail)
                startCompose(.reply(messageID: target.id, all: true))
                compose?.body = AttributedString(text)
                assistant.say("Rascunho (gerado por IA) está no editor. Revise antes de enviar.")
            case .answer:
                assistant.say(reply.say)
            }
        } catch {
            assistant.say("Erro: \(error.localizedDescription)")
        }
    }
}

struct AssistantPanel: View {
    @Environment(AppModel.self) private var model
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var assistant = model.assistant
        VStack(spacing: 0) {
            HStack {
                Label("Aba lateral", systemImage: "sparkles").font(.headline)
                Spacer()
                Text(model.contextDescription).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            .padding(10)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if assistant.log.isEmpty {
                            Text("Exemplos: \"acha a proposta que a Marina mandou em agosto\", \"move tudo isso para Obras\", \"resume\", \"responde dizendo que aprovo\".")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(assistant.log) { e in
                            Text(e.text)
                                .font(.callout)
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: e.fromUser ? .trailing : .leading)
                                .background(e.fromUser ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                .id(e.id)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: assistant.log.count) { _, _ in if let last = assistant.log.last { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
            Divider()
            if assistant.pending != nil {
                HStack {
                    Button("Confirmar (y)") { Task { await assistant.confirm() } }.buttonStyle(.borderedProminent)
                    Button("Cancelar (n)") { assistant.cancel() }
                }
                .padding(8)
            }
            HStack {
                TextField("Pergunte ou peça algo…", text: $assistant.input)
                    .textFieldStyle(.roundedBorder).focused($focused)
                    .onSubmit { Task { await model.ask(assistant.input) } }
                if assistant.isBusy { ProgressView().controlSize(.small) }
            }
            .padding(8)
        }
        .frame(minWidth: 280)
        .onAppear { focused = true }
        .onKeyPress(characters: .init(charactersIn: "yn")) { press in
            guard assistant.pending != nil, !focused else { return .ignored }
            if press.characters == "y" { Task { await assistant.confirm() } } else { assistant.cancel() }
            return .handled
        }
    }
}
