import Foundation

/// Sincroniza uma pasta do servidor para o Índice local via delta do Graph.
/// Primeira execução: percorre a pasta inteira (backfill). Depois: só o que mudou.
public struct MailSync: Sendable {
    public let graph: GraphClient
    public let store: MailStore

    public init(graph: GraphClient, store: MailStore) {
        self.graph = graph
        self.store = store
    }

    /// Cabeçalhos: páginas maiores e corpo em HTML (o texto puro é derivado localmente).
    static let headers = ["Prefer": "odata.maxpagesize=100"]

    /// Sincroniza `folder` ("inbox", "sentitems"...). Chama `progress` a cada página com o total acumulado.
    public func sync(folder: String, progress: (@Sendable (Int) -> Void)? = nil) async throws {
        var url = try store.deltaLink(for: folder) ?? Self.initialDeltaURL(folder: folder)
        var total = 0
        while true {
            let page: DeltaPage<DeltaMessage> = try await graph.get(url: url, headers: Self.headers)
            let removed = page.value.filter(\.removed).map(\.id)
            let changed = page.value.compactMap(\.message).map { StoredMessage(message: $0, folder: folder) }
            if !removed.isEmpty { try store.delete(ids: removed) }
            if !changed.isEmpty { try store.upsert(changed) }
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

    static func initialDeltaURL(folder: String) -> URL {
        var components = URLComponents(url: GraphClient.baseURL.appendingPathComponent("me/mailFolders/\(folder)/messages/delta"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "$select", value: Message.listFields + ",body"),
            .init(name: "$expand", value: ExtendedProperty.expand),
        ]
        return components.url!
    }
}
