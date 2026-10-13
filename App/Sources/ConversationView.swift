import MasterMailCore
import SwiftUI

/// A Conversa: mensagens em ordem cronológica, cada uma dizendo a quem responde; Ramos marcados e recuados.
struct ConversationView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    Text(model.openMessage?.subject.isEmpty == false ? model.openMessage!.subject : "(sem assunto)")
                        .font(.title2.bold())
                        .padding(.bottom, 4)
                    ForEach(model.conversation) { node in
                        MessageCard(node: node, parent: parent(of: node), isExpanded: model.expanded.contains(node.id), isNewest: node.id == model.conversation.last?.id)
                            .padding(.leading, CGFloat(min(node.depth, 4)) * 16)
                            .id(node.id)
                    }
                }
                .padding()
            }
            .onChange(of: model.openMessage?.id) { _, id in
                if let id { withAnimation { proxy.scrollTo(id, anchor: .top) } }
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
    @State private var bodyHeight: CGFloat = 200

    private var m: StoredMessage { node.message }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { Task { await model.toggle(node.id) } } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(m.fromName.isEmpty ? m.fromAddress : m.fromName).fontWeight(.semibold)
                        Text(m.fromAddress).foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        if node.isBranch {
                            Text("Ramo").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.orange.opacity(0.2), in: Capsule()).foregroundStyle(.orange)
                        }
                        if isNewest {
                            Text("Mais recente").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.blue.opacity(0.15), in: Capsule()).foregroundStyle(.blue)
                        }
                        Text(m.receivedAt, format: .dateTime.day().month().hour().minute()).font(.caption).foregroundStyle(.secondary)
                    }
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
                MessageBodyView(html: m.bodyHTML, text: m.bodyText, height: $bodyHeight)
                    .frame(height: bodyHeight)
            }
        }
        .padding(12)
        .background(isNewest ? Color.accentColor.opacity(0.06) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(node.isBranch ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2)))
    }
}
