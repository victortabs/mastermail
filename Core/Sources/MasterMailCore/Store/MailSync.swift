import Foundation

/// Sincroniza uma pasta do servidor para o Índice local via delta do Graph.
/// Primeira execução: percorre a pasta inteira (backfill). Depois: só o que mudou.
public struct MailSync: Sendable {
    public let graph: GraphClient
    public let store: MailStore
    public let queue: ActionQueue?

    public init(graph: GraphClient, store: MailStore, queue: ActionQueue? = nil) {
        self.graph = graph
        self.store = store
        self.queue = queue
    }

    /// Cabeçalhos: páginas maiores e corpo em HTML (o texto puro é derivado localmente).
    static let headers = ["Prefer": "odata.maxpagesize=100"]

    /// Sincroniza `folder` ("inbox", "sentitems"...). Chama `progress` a cada página com o total acumulado.
    public func sync(folder: String, progress: (@Sendable (Int) -> Void)? = nil) async throws {
        let savedURL = try store.deltaLink(for: folder)
        var url = savedURL ?? Self.initialDeltaURL(folder: folder)
        var canRestart = savedURL != nil
        var total = 0
        while true {
            try Task.checkCancellation()
            let page: DeltaPage<DeltaMessage>
            do {
                page = try await graph.get(url: url, headers: Self.headers)
            } catch let error as GraphError {
                // Cursores antigos podem carregar a seleção inválida dentro de um token opaco.
                // Recupera uma vez, sem apagar o índice nem a autorização Microsoft.
                if canRestart, Self.needsNewCursor(error) {
                    canRestart = false
                    try store.clearDeltaLink(for: folder)
                    url = Self.initialDeltaURL(folder: folder)
                    continue
                }
                throw error
            }
            let removed = page.value.filter(\.removed).map(\.id)
            if !removed.isEmpty { try store.delete(ids: removed) }
            var resolved: [String: StoredMessage] = [:]
            for item in page.value where !item.removed {
                if let message = item.message {
                    resolved[item.id] = StoredMessage(message: message, folder: folder)
                } else if !item.needsFullMessage, let readState = item.readState,
                          var cached = try resolved[item.id] ?? store.message(id: item.id) {
                    cached.isRead = readState
                    resolved[item.id] = cached
                } else {
                    // Item ainda desconhecido ou outra mudança parcial: lê a mensagem completa.
                    do {
                        resolved[item.id] = StoredMessage(message: try await graph.message(id: item.id), folder: folder)
                    } catch let error as GraphError {
                        guard case .http(status: 404, body: _) = error else { throw error }
                        // A mensagem pode ter sido removida entre o delta e a leitura individual.
                        resolved.removeValue(forKey: item.id)
                        try store.delete(ids: [item.id])
                    }
                }
            }
            let changed = Array(resolved.values)
            if !changed.isEmpty { try store.upsert(changed, preserving: await queue?.pendingActions ?? []) }
            total += page.value.count
            progress?(total)
            if let next = page.nextLink {
                // Guarda o nextLink: se o app fechar no meio do backfill, retoma daqui.
                try store.setDeltaLink(next, for: folder)
                url = next
            } else if let delta = page.deltaLink {
                try store.setDeltaLink(delta, for: folder)
                return
            } else {
                return
            }
        }
    }

    private static func needsNewCursor(_ error: GraphError) -> Bool {
        guard case let .http(status, body) = error else { return false }
        return status == 410 || status == 400 && body.contains("meetingMessageType")
    }

    static func initialDeltaURL(folder: String) -> URL {
        var components = URLComponents(url: GraphClient.baseURL.appendingPathComponent("me/mailFolders/\(folder)/messages/delta"), resolvingAgainstBaseURL: false)!
        // A Pasta local é reconciliada à parte (localFolderAssignments).
        components.queryItems = [.init(name: "$select", value: Message.listFields + ",body")]
        return components.url!
    }
}
