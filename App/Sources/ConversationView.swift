import MasterMailCore
import SwiftUI

/// A Conversa: cronológica, "em resposta a", Ramos recuados, mais recente aberta, resposta inline no fim.
struct ConversationView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    Text(model.openMessage?.subject.isEmpty == false ? model.openMessage!.subject : "(sem assunto)")
                        .font(.title2.bold()).padding(.bottom, 4)
                    ForEach(model.conversation) { node in
                        MessageCard(node: node, parent: parent(of: node),
                                    isExpanded: model.expanded.contains(node.id),
                                    isNewest: node.id == model.conversation.last?.id,
                                    isFocused: model.conversationFocused && model.focusedNodeID == node.id)
                            .padding(.leading, CGFloat(min(node.depth, 4)) * 16)
                            .id(node.id)
                    }
                    if let compose = model.compose, compose.mode != .new {
                        ComposeEditor(model: compose, inline: true)
                            .id("compose")
                    }
                }
                .padding()
            }
            .onChange(of: model.openMessage?.id) { _, _ in
                if let last = model.conversation.last?.id { withAnimation { proxy.scrollTo(last, anchor: .top) } }
            }
            .onChange(of: model.focusedNodeID) { _, id in
                if let id, model.conversationFocused { withAnimation { proxy.scrollTo(id, anchor: .center) } }
            }
            .onChange(of: model.compose?.id) { _, id in
                if id != nil { withAnimation { proxy.scrollTo("compose", anchor: .bottom) } }
            }
        }
    }

    private func parent(of node: ConversationNode) -> ConversationNode? {
        node.parentID.flatMap { pid in model.conversation.first { $0.id == pid } }
    }
}

struct MessageCard: View {
    @Environment(AppModel.self) private var model
    let node: ConversationNode
    let parent: ConversationNode?
    let isExpanded: Bool
    let isNewest: Bool
    let isFocused: Bool
    @State private var bodyHeight: CGFloat = 200
    @State private var attachments: [Attachment] = []
    @State private var reminderSheet = false
    @State private var eventSheet = false

    private var m: StoredMessage { node.message }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { Task { await model.toggle(node.id) } } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(m.fromName.isEmpty ? m.fromAddress : m.fromName).fontWeight(.semibold)
                        Text(m.fromAddress).foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        if node.isBranch { Badge("Ramo", .orange) }
                        if isNewest { Badge("Mais recente", .blue) }
                        if m.isFlagged { Image(systemName: "flag.fill").foregroundStyle(.orange).font(.caption) }
                        Text(m.receivedAt, format: .dateTime.day().month().hour().minute()).font(.caption).foregroundStyle(.secondary)
                    }
                    if !m.categories.isEmpty { CategoryChips(categories: m.categories) }
                    if let parent {
                        Label("em resposta a \(parent.message.fromName.isEmpty ? parent.message.fromAddress : parent.message.fromName), \(parent.message.receivedAt, format: .dateTime.day().month().hour().minute())", systemImage: "arrow.turn.down.right")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if !isExpanded {
                        Text(m.preview).font(.callout).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isExpanded {
                if !m.recipients.isEmpty {
                    Text("Para: " + m.recipients).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                }
                if m.meetingMessageType == "meetingRequest" { InviteBar(messageID: m.id) }
                HStack(spacing: 8) {
                    Button { reminderSheet = true } label: { Label("Lembrete", systemImage: "checklist") }
                    Button { eventSheet = true } label: { Label("Evento", systemImage: "calendar.badge.plus") }
                    Button { model.availabilityRecipient = m.fromName.isEmpty ? m.fromAddress : "\(m.fromName) <\(m.fromAddress)>" } label: {
                        Label("Disponibilidade", systemImage: "calendar.badge.clock")
                    }
                    .help("Enviar seus horários livres para quem mandou")
                    if let tipo = m.tipo.flatMap(Tipo.init(rawValue:)), tipo == .newsletter || tipo == .promocao {
                        Button { Task { await model.unsubscribe(m) } } label: { Label("Cancelar inscrição", systemImage: "xmark.circle") }
                    }
                    Spacer()
                }
                .controlSize(.small)
                if m.hasAttachments {
                    AttachmentStrip(messageID: m.id, attachments: $attachments)
                }
                let signals = HTMLText.phishingSignals(fromName: m.fromName, fromAddress: m.fromAddress, html: m.bodyHTML)
                if !signals.isEmpty {
                    Label(signals.joined(separator: " "), systemImage: "exclamationmark.shield.fill")
                        .font(.caption).foregroundStyle(.red).padding(6)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }
                let allowRemote = model.imagesAllowed(m)
                if let html = m.bodyHTML, !allowRemote, html.contains("http") {
                    HStack(spacing: 6) {
                        Button("Mostrar imagens") { model.remoteImagesAllowed.insert(m.id) }
                        Menu("Sempre de…") {
                            Button(m.fromAddress) { model.trustImages(from: m, wholeDomain: false) }
                            Button("@" + (m.fromAddress.split(separator: "@").last.map(String.init) ?? "")) { model.trustImages(from: m, wholeDomain: true) }
                        }.fixedSize()
                    }
                    .controlSize(.small)
                }
                MessageBodyView(html: m.bodyHTML, text: m.bodyText, allowRemote: allowRemote, height: $bodyHeight)
                    .frame(height: bodyHeight)
                    .id(allowRemote)
            }
        }
        .padding(12)
        .background(isNewest ? Color.accentColor.opacity(0.06) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isFocused ? Color.accentColor : (node.isBranch ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2)), lineWidth: isFocused ? 2 : 1))
        .sheet(isPresented: $reminderSheet) { ReminderSheet(message: m) }
        .sheet(isPresented: $eventSheet) {
            if let cal = model.calendar {
                EventEditor(cal: cal, defaultStart: Date(), prefillTitle: m.subject, prefillAttendees: ([m.fromAddress] + Recipient.parseList(m.recipients).compactMap(\.emailAddress.address)).filter { $0.lowercased() != model.accountEmail }.joined(separator: ", "), prefillNotes: m.preview)
            }
        }
    }
}

/// Convite recebido por e-mail: Aceitar / Talvez / Recusar atualizam a Agenda Microsoft (requisito).
struct InviteBar: View {
    @Environment(AppModel.self) private var model
    let messageID: String
    @State private var event: CalendarEvent?
    @State private var done = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark").foregroundStyle(.blue)
            if let event {
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title).font(.callout.weight(.semibold))
                    Text("\(event.start.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())) – \(event.end.formatted(date: .omitted, time: .shortened))\(event.location.map { " · \($0)" } ?? "")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if done || (event.response != nil && event.response != "notResponded" && event.response != "none") {
                    Text(label(event.response)).font(.caption).foregroundStyle(.secondary)
                } else {
                    Button("Aceitar") { respond(event, "accept") }.buttonStyle(.borderedProminent)
                    Button("Talvez") { respond(event, "tentativelyAccept") }
                    Button("Recusar") { respond(event, "decline") }
                }
            } else {
                Text("Convite de reunião").font(.callout)
                Spacer()
                ProgressView().controlSize(.small)
            }
        }
        .controlSize(.small)
        .padding(8)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        .task(id: messageID) { event = try? await model.client?.event(forMeetingMessage: messageID) }
    }

    private func label(_ r: String?) -> String {
        switch r {
        case "accepted": "Aceito"
        case "tentativelyAccepted": "Talvez"
        case "declined": "Recusado"
        case "organizer": "Você organiza"
        default: ""
        }
    }

    private func respond(_ e: CalendarEvent, _ action: String) {
        Task {
            await model.calendar?.respond(e, action)
            done = true
            model.showToast(action == "accept" ? "Aceito e na agenda" : action == "decline" ? "Recusado" : "Marcado como talvez")
        }
    }
}

/// Anexos não-inline: nome e tamanho; clique abre com o app padrão (baixa para a pasta temporária); "Salvar" vai para Downloads.
struct AttachmentStrip: View {
    @Environment(AppModel.self) private var model
    let messageID: String
    @Binding var attachments: [Attachment]
    @State private var busy: String?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(attachments) { a in
                Menu {
                    Button("Abrir") { Task { await open(a, save: false) } }
                    Button("Salvar em Downloads") { Task { await open(a, save: true) } }
                } label: {
                    Label("\(a.name ?? "anexo")\(a.size.map { " · \(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file))" } ?? "")", systemImage: busy == a.id ? "arrow.down.circle" : "paperclip")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton).fixedSize()
            }
            if attachments.isEmpty { Text("carregando anexos…").font(.caption).foregroundStyle(.tertiary) }
        }
        .task(id: messageID) {
            if attachments.isEmpty, let graph = model.client {
                attachments = (try? await graph.attachments(messageID: messageID)) ?? []
            }
        }
    }

    private func open(_ a: Attachment, save: Bool) async {
        guard let graph = model.client else { return }
        busy = a.id
        defer { busy = nil }
        do {
            let data = try await graph.attachmentData(messageID: messageID, attachmentID: a.id)
            let dir = save ? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                           : FileManager.default.temporaryDirectory.appendingPathComponent("MasterMail", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var url = dir.appendingPathComponent(a.name ?? "anexo")
            var n = 1
            while save, FileManager.default.fileExists(atPath: url.path) {
                url = dir.appendingPathComponent("\((a.name ?? "anexo") as NSString).deletingPathExtension) \(n).\(((a.name ?? "") as NSString).pathExtension)"); n += 1
            }
            try data.write(to: url)
            if save { model.showToast("Salvo em Downloads: \(url.lastPathComponent)") } else { NSWorkspace.shared.open(url) }
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
}

/// Lembrete a partir da mensagem (CONTEXT.md: nasce no Lembretes.app).
struct ReminderSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let message: StoredMessage
    @State private var withDue = true
    @State private var due = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)!

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lembrete").font(.headline)
            Text(message.subject.isEmpty ? "(sem assunto)" : message.subject).lineLimit(2)
            Toggle("Com data", isOn: $withDue)
            DatePicker("Quando", selection: $due).disabled(!withDue)
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Criar") { Task { await model.createReminder(from: message, due: withDue ? due : nil); dismiss() } }.keyboardShortcut(.defaultAction)
            }
        }
        .padding().frame(width: 360)
    }
}

struct Badge: View {
    let text: String
    let color: Color
    init(_ text: String, _ color: Color) { self.text = text; self.color = color }

    var body: some View {
        Text(text).font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule()).foregroundStyle(color)
    }
}
