import Foundation
import GRDB

/// Uma Mensagem como fica no Índice local (ver CONTEXT.md). Texto puro de tudo; HTML guardado junto por enquanto.
public struct StoredMessage: Codable, Sendable, Hashable, Identifiable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "message"

    public var id: String
    public var folder: String
    public var conversationId: String?
    public var conversationIndex: String?
    public var subject: String
    public var fromName: String
    public var fromAddress: String
    public var recipients: String // "Nome <a@b>, Nome2 <c@d>" (Para + Cc), só para exibir e buscar
    public var receivedAt: Date
    public var isRead: Bool
    public var hasAttachments: Bool
    public var preview: String
    /// Categorias do Outlook (ver CONTEXT.md: Categoria). GRDB guarda como JSON.
    public var categories: [String]
    /// Pasta local (CONTEXT.md). nil = está na Caixa de entrada (se a pasta do servidor for a Inbox).
    public var localFolder: String?
    /// Adiar (CONTEXT.md): escondida da Caixa de entrada até esta hora. Só local.
    public var snoozedUntil: Date?
    public var isFlagged: Bool = false
    public var meetingMessageType: String?
    public var bodyText: String
    /// HTML só dos últimos 12 meses (requisito); mais antigo fica nil e é baixado ao abrir.
    public var bodyHTML: String?
    // Camada de IA (CONTEXT.md: Tipo, Importante, Justificativa, Triagem). Preenchidos pela ClassificationPipeline.
    public var tipo: String?
    public var importante: Bool = false
    public var justificativa: String?
    public var classifiedAt: Date?
    public var triagemConfirmada: Bool = false

    public static let htmlRetention: TimeInterval = 365 * 86400

    public init(message m: Message, folder: String) {
        id = m.id
        self.folder = folder
        conversationId = m.conversationId
        conversationIndex = m.conversationIndex
        subject = m.subject ?? ""
        fromName = m.from?.emailAddress.name ?? ""
        fromAddress = m.from?.emailAddress.address ?? ""
        recipients = ((m.toRecipients ?? []) + (m.ccRecipients ?? [])).map {
            let name = $0.emailAddress.name ?? ""
            let address = $0.emailAddress.address ?? ""
            return name.isEmpty ? address : "\(name) <\(address)>"
        }.joined(separator: ", ")
        receivedAt = m.receivedDateTime
        isRead = m.isRead
        hasAttachments = m.hasAttachments
        preview = m.bodyPreview ?? ""
        categories = m.categories ?? []
        localFolder = m.localFolder
        isFlagged = m.isFlagged
        meetingMessageType = m.meetingMessageType
        if let body = m.body {
            if body.contentType.lowercased() == "html" {
                bodyHTML = m.receivedDateTime.timeIntervalSinceNow > -Self.htmlRetention ? body.content : nil
                bodyText = HTMLText.plainText(from: body.content)
            } else {
                bodyHTML = nil
                bodyText = body.content
            }
        } else {
            bodyHTML = nil
            bodyText = preview
        }
    }
}

/// Estado de sincronização por pasta do servidor.
struct SyncState: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "sync_state"
    var folder: String
    var deltaLink: String
}

/// O Índice local: SQLite com busca full-text (FTS5). Thread-safe (DatabasePool).
public final class MailStore: Sendable {
    public let pool: DatabasePool

    public init(path: String) throws {
        try FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        pool = try DatabasePool(path: path)
        try Self.migrator.migrate(pool)
    }

    /// Banco descartável em arquivo temporário, para testes (DatabasePool não roda em memória).
    public static func inMemory() throws -> MailStore {
        try MailStore(path: FileManager.default.temporaryDirectory.appendingPathComponent("mastermail-\(UUID().uuidString).sqlite").path)
    }

    /// `~/Library/Application Support/MasterMail/mail.sqlite`
    public static func defaultPath() -> String {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("MasterMail/mail.sqlite").path
    }

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "message") { t in
                t.primaryKey("id", .text)
                t.column("folder", .text).notNull().indexed()
                t.column("conversationId", .text).indexed()
                t.column("conversationIndex", .text)
                t.column("subject", .text).notNull()
                t.column("fromName", .text).notNull()
                t.column("fromAddress", .text).notNull().indexed()
                t.column("recipients", .text).notNull()
                t.column("receivedAt", .datetime).notNull().indexed()
                t.column("isRead", .boolean).notNull()
                t.column("hasAttachments", .boolean).notNull()
                t.column("preview", .text).notNull()
                t.column("bodyText", .text).notNull()
                t.column("bodyHTML", .text)
            }
            try db.create(virtualTable: "message_ft", using: FTS5()) { t in
                t.synchronize(withTable: "message")
                t.tokenizer = .unicode61(diacritics: .remove)
                t.column("subject")
                t.column("fromName")
                t.column("fromAddress")
                t.column("recipients")
                t.column("bodyText")
            }
            try db.create(table: "sync_state") { t in
                t.primaryKey("folder", .text)
                t.column("deltaLink", .text).notNull()
            }
        }
        // v2: categorias + pasta passa a ser o id real do servidor. Recomeça o índice (ainda não há usuários).
        migrator.registerMigration("v2") { db in
            try db.drop(table: "message_ft")
            try db.drop(table: "message")
            try db.drop(table: "sync_state")
            try db.create(table: "message") { t in
                t.primaryKey("id", .text)
                t.column("folder", .text).notNull().indexed()
                t.column("conversationId", .text).indexed()
                t.column("conversationIndex", .text)
                t.column("subject", .text).notNull()
                t.column("fromName", .text).notNull()
                t.column("fromAddress", .text).notNull().indexed()
                t.column("recipients", .text).notNull()
                t.column("receivedAt", .datetime).notNull().indexed()
                t.column("isRead", .boolean).notNull()
                t.column("hasAttachments", .boolean).notNull()
                t.column("preview", .text).notNull()
                t.column("categories", .text).notNull().defaults(to: "[]")
                t.column("bodyText", .text).notNull()
                t.column("bodyHTML", .text)
            }
            try db.create(virtualTable: "message_ft", using: FTS5()) { t in
                t.synchronize(withTable: "message")
                t.tokenizer = .unicode61(diacritics: .remove)
                t.column("subject")
                t.column("fromName")
                t.column("fromAddress")
                t.column("recipients")
                t.column("bodyText")
            }
            try db.create(table: "sync_state") { t in
                t.primaryKey("folder", .text)
                t.column("deltaLink", .text).notNull()
            }
        }
        migrator.registerMigration("v3") { db in
            try db.alter(table: "message") { t in t.add(column: "localFolder", .text).indexed() }
            try db.create(table: "local_folder") { t in t.primaryKey("name", .text) }
        }
        migrator.registerMigration("v4") { db in
            try db.alter(table: "message") { t in
                t.add(column: "snoozedUntil", .datetime).indexed()
                t.add(column: "isFlagged", .boolean).notNull().defaults(to: false)
            }
        }
        migrator.registerMigration("people-1", migrate: migratePeople)
        registerAIMigrations(&migrator)
        migrator.registerMigration("v5") { db in
            try db.alter(table: "message") { t in t.add(column: "meetingMessageType", .text) }
        }
        migrator.registerMigration("v6-account-owner") { db in
            try db.create(table: "account_owner") { t in
                t.primaryKey("key", .text)
                t.column("identifier", .text).notNull()
                t.column("displayName", .text).notNull()
            }
        }
        return migrator
    }

    /// A v1 tem uma única conta. Impede reutilizar o índice e a fila de outra pessoa ao reconectar.
    public func claimAccount(identifier: String, displayName: String) throws {
        try pool.write { db in
            if let owner = try Row.fetchOne(db, sql: "SELECT identifier, displayName FROM account_owner WHERE key = 'primary'") {
                let stored: String = owner["identifier"]
                guard stored == identifier else { throw AccountMismatch(expected: owner["displayName"]) }
            } else {
                try db.execute(sql: "INSERT INTO account_owner(key, identifier, displayName) VALUES ('primary', ?, ?)", arguments: [identifier, displayName])
            }
        }
    }

    public struct AccountMismatch: Error, LocalizedError, Sendable {
        public let expected: String
        public var errorDescription: String? {
            "Este Índice local pertence a \(expected). Reconecte essa conta. A v1 usa uma única conta por instalação."
        }
    }

    // MARK: Leitura

    /// Mensagens de uma pasta do servidor que não estão em Pasta local nem adiadas (é a Caixa de entrada quando folder = Inbox).
    public func messages(in folder: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage
                .filter(Column("folder") == folder && Column("localFolder") == nil)
                .filter(Column("snoozedUntil") == nil || Column("snoozedUntil") <= Date())
                .order(Column("receivedAt").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
        }
    }

    public func snoozed(limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(Column("snoozedUntil") > Date()).order(Column("snoozedUntil")).limit(limit, offset: offset).fetchAll(db)
        }
    }

    public func setSnooze(id: String, until: Date?) throws {
        try pool.write { db in try db.execute(sql: "UPDATE message SET snoozedUntil = ? WHERE id = ?", arguments: [until, id]) }
    }

    public func setFlagged(id: String, _ flagged: Bool) throws {
        try pool.write { db in try db.execute(sql: "UPDATE message SET isFlagged = ? WHERE id = ?", arguments: [flagged, id]) }
    }

    /// Mensagens recebidas (na pasta `inbox`) que são a última da Conversa e vieram de outra pessoa: esperam resposta sua.
    public func awaitingMyReply(inbox: String, me: String, limit: Int = 200) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.fetchAll(db, sql: """
                SELECT m.* FROM message m
                WHERE m.folder = ? AND m.localFolder IS NULL AND lower(m.fromAddress) != lower(?)
                  AND m.conversationId IS NOT NULL
                  AND m.receivedAt = (SELECT max(receivedAt) FROM message x WHERE x.conversationId = m.conversationId)
                  AND EXISTS (SELECT 1 FROM message y WHERE y.conversationId = m.conversationId AND lower(y.fromAddress) = lower(?))
                ORDER BY m.receivedAt DESC LIMIT ?
                """, arguments: [inbox, me, me, limit])
        }
    }

    /// Mensagens que você enviou (pasta `sent`) há mais de `days` dias e que continuam sendo a última da Conversa: sem resposta deles.
    public func awaitingTheirReply(sent: String, me: String, days: Int = 2, limit: Int = 200) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.fetchAll(db, sql: """
                SELECT m.* FROM message m
                WHERE m.folder = ? AND m.conversationId IS NOT NULL AND m.receivedAt < ?
                  AND m.receivedAt = (SELECT max(receivedAt) FROM message x WHERE x.conversationId = m.conversationId)
                ORDER BY m.receivedAt DESC LIMIT ?
                """, arguments: [sent, Date().addingTimeInterval(-Double(days) * 86400), limit])
        }
    }

    public func messages(localFolder name: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage
                .filter(Column("localFolder") == name)
                .order(Column("receivedAt").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
        }
    }

    // MARK: Pastas locais (nomes = tabela própria ∪ valores presentes nas mensagens)

    public func localFolders() throws -> [String] {
        try pool.read { db in
            let own = try String.fetchAll(db, sql: "SELECT name FROM local_folder")
            let used = try String.fetchAll(db, sql: "SELECT DISTINCT localFolder FROM message WHERE localFolder IS NOT NULL")
            return Array(Set(own + used)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
    }

    public func createLocalFolder(_ name: String) throws {
        try pool.write { db in try db.execute(sql: "INSERT OR IGNORE INTO local_folder(name) VALUES (?)", arguments: [name]) }
    }

    /// Renomeia no índice e devolve os ids das mensagens afetadas (o chamador grava no servidor).
    public func renameLocalFolder(_ old: String, to new: String) throws -> [String] {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM local_folder WHERE name = ?", arguments: [old])
            try db.execute(sql: "INSERT OR IGNORE INTO local_folder(name) VALUES (?)", arguments: [new])
            let ids = try String.fetchAll(db, sql: "SELECT id FROM message WHERE localFolder = ?", arguments: [old])
            try db.execute(sql: "UPDATE message SET localFolder = ? WHERE localFolder = ?", arguments: [new, old])
            return ids
        }
    }

    /// Aplica o que o servidor diz: mensagens listadas ganham a pasta; as demais com pasta local perdem.
    public func applyLocalFolders(_ assignments: [String: String], preserving pendingIDs: Set<String> = []) throws {
        try pool.write { db in
            var request = StoredMessage.filter(Column("localFolder") != nil)
            if !pendingIDs.isEmpty { request = request.filter(!pendingIDs.contains(Column("id"))) }
            _ = try request.updateAll(db, Column("localFolder").set(to: nil as String?))
            for (id, name) in assignments where !pendingIDs.contains(id) {
                try db.execute(sql: "UPDATE message SET localFolder = ? WHERE id = ?", arguments: [name, id])
            }
        }
    }

    public func setLocalFolder(id: String, _ name: String?) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET localFolder = ? WHERE id = ?", arguments: [name, id])
        }
    }

    /// true quando a primeira indexação da pasta terminou (o link guardado é um deltaLink, não um nextLink).
    public func isFullyIndexed(folder: String) throws -> Bool {
        try pool.read { db in
            try SyncState.fetchOne(db, key: folder)?.deltaLink.contains("deltatoken") ?? false
        }
    }

    public func hasSynced(folder: String) throws -> Bool {
        try pool.read { db in try SyncState.fetchOne(db, key: folder) != nil }
    }

    public func message(id: String) throws -> StoredMessage? {
        try pool.read { db in try StoredMessage.fetchOne(db, key: id) }
    }

    /// Mensagens de uma Conversa, em ordem cronológica.
    public func conversation(id: String) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(Column("conversationId") == id).order(Column("receivedAt")).fetchAll(db)
        }
    }

    public func count(in folder: String) throws -> Int {
        try pool.read { db in try StoredMessage.filter(Column("folder") == folder).fetchCount(db) }
    }

    /// Busca full-text, melhores primeiro. Aceita a sintaxe do FTS5 (aspas, OR, prefixo*); termos soltos viram prefixo.
    public func search(_ query: String, limit: Int = 100) throws -> [StoredMessage] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let pattern = FTS5Pattern(matchingAllPrefixesIn: trimmed)
        guard let pattern else { return [] }
        return try pool.read { db in
            try StoredMessage.fetchAll(db, sql: """
                SELECT message.* FROM message
                JOIN message_ft ON message_ft.rowid = message.rowid
                WHERE message_ft MATCH ?
                ORDER BY bm25(message_ft, 10.0, 5.0, 5.0, 2.0, 1.0), message.receivedAt DESC
                LIMIT ?
                """, arguments: [pattern, limit])
        }
    }

    // MARK: Escrita

    /// Grava o que veio do servidor sem perder o que é só local (Pasta local reconciliada, Adiar).
    public func upsert(_ messages: [StoredMessage], preserving pendingActions: [PendingAction] = []) throws {
        let pendingByMessage = Dictionary(grouping: pendingActions, by: \.messageID)
        try pool.write { db in
            for var m in messages {
                // A sincronização recria o registro; o que é só local (Pasta local reconciliada, Adiar,
                // classificação da IA) precisa sobreviver ao delta.
                if let existing = try StoredMessage.fetchOne(db, key: m.id) {
                    if m.localFolder == nil { m.localFolder = existing.localFolder }
                    m.snoozedUntil = existing.snoozedUntil
                    if m.bodyHTML == nil { m.bodyHTML = existing.bodyHTML }
                    m.tipo = existing.tipo
                    m.importante = existing.importante
                    m.justificativa = existing.justificativa
                    m.classifiedAt = existing.classifiedAt
                    m.triagemConfirmada = existing.triagemConfirmada
                }
                for action in pendingByMessage[m.id] ?? [] {
                    switch action {
                    case let .markRead(_, value): m.isRead = value
                    case let .flag(_, value): m.isFlagged = value
                    case let .localFolder(_, value): m.localFolder = value
                    case let .categories(_, value): m.categories = value
                    case .move: break
                    }
                }
                try m.save(db)
            }
        }
    }

    /// Grava somente o corpo baixado, preservando ações feitas enquanto a rede respondia.
    public func cacheBody(id: String, html: String?) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET bodyHTML = ? WHERE id = ?", arguments: [html, id])
        }
    }

    /// Movimentações do servidor podem trocar o id; preserva os metadados locais em uma transação.
    public func replace(id: String, with message: StoredMessage) throws {
        try pool.write { db in
            _ = try StoredMessage.deleteOne(db, key: id)
            try message.save(db)
        }
    }

    public func delete(ids: [String]) throws {
        try pool.write { db in _ = try StoredMessage.deleteAll(db, keys: ids) }
    }

    public func setRead(id: String, _ isRead: Bool) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET isRead = ? WHERE id = ?", arguments: [isRead, id])
        }
    }

    func deltaLink(for folder: String) throws -> URL? {
        try pool.read { db in
            try SyncState.fetchOne(db, key: folder).flatMap { URL(string: $0.deltaLink) }
        }
    }

    func setDeltaLink(_ url: URL, for folder: String) throws {
        try pool.write { db in try SyncState(folder: folder, deltaLink: url.absoluteString).save(db) }
    }

    /// Reinicia somente o cursor; conserva mensagens e organização locais.
    func clearDeltaLink(for folder: String) throws {
        try pool.write { db in _ = try SyncState.deleteOne(db, key: folder) }
    }
}
