import Foundation

/// Uma escrita no servidor que ainda não aconteceu (requisito: fila offline). A ação local já foi feita.
public enum PendingAction: Codable, Sendable, Equatable {
    case markRead(id: String, isRead: Bool)
    case flag(id: String, flagged: Bool)
    case move(id: String, destination: String)
    case localFolder(id: String, name: String?)
    case categories(id: String, categories: [String])

    var messageID: String {
        switch self {
        case let .markRead(id, _), let .flag(id, _), let .move(id, _), let .localFolder(id, _), let .categories(id, _): id
        }
    }
}

/// Fila persistida em arquivo; drena em ordem, para no primeiro erro de rede e tenta de novo no próximo ciclo.
public actor ActionQueue {
    public let fileURL: URL
    private(set) var items: [PendingAction]

    public init(fileURL: URL) {
        self.fileURL = fileURL
        items = (try? JSONDecoder().decode([PendingAction].self, from: Data(contentsOf: fileURL))) ?? []
    }

    public static func `default`() -> ActionQueue {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return ActionQueue(fileURL: base.appendingPathComponent("MasterMail/pending-actions.json"))
    }

    public var count: Int { items.count }

    public func enqueue(_ action: PendingAction) {
        items.append(action)
        persist()
    }

    /// Executa tudo o que der. Devolve quantas ações foram concluídas. Erros de rede param a drenagem; HTTP 4xx descarta a ação.
    @discardableResult
    public func drain(using graph: GraphClient) async -> Int {
        var done = 0
        while let action = items.first {
            do {
                try await perform(action, graph)
                items.removeFirst()
                done += 1
            } catch let error as GraphError {
                if case let .http(status, _) = error, (400 ..< 500).contains(status) {
                    items.removeFirst() // o servidor recusou de vez (mensagem apagada etc.): não adianta insistir
                    continue
                }
                break
            } catch {
                break // sem rede: fica para o próximo ciclo
            }
        }
        persist()
        return done
    }

    private func perform(_ action: PendingAction, _ graph: GraphClient) async throws {
        switch action {
        case let .markRead(id, isRead): try await graph.markRead(id: id, isRead)
        case let .flag(id, flagged): try await graph.setFlag(id: id, flagged)
        case let .move(id, destination): try await graph.move(id: id, destinationID: destination)
        case let .localFolder(id, name): try await graph.setLocalFolder(id: id, name)
        case let .categories(id, categories): try await graph.setCategories(id: id, categories)
        }
    }

    private func persist() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(items).write(to: fileURL, options: .atomic)
    }
}
