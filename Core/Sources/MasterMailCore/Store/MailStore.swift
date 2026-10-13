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
    public var bodyText: String
    /// HTML só dos últimos 12 meses (requisito); mais antigo fica nil e é baixado ao abrir.
    public var bodyHTML: String?

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
        migrator.registerMigration("people-1", migrate: migratePeople)
        return migrator
    }

    // MARK: Leitura

    /// Mensagens de uma pasta do servidor que não estão em Pasta local (é a Caixa de entrada quando folder = Inbox).
    public func messages(in folder: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage
                .filter(Column("folder") == folder && Column("localFolder") == nil)
                .order(Column("receivedAt").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
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
    public func applyLocalFolders(_ assignments: [String: String]) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET localFolder = NULL WHERE localFolder IS NOT NULL")
            for (id, name) in assignments {
                try db.execute(sql: "UPDATE message SET localFolder = ? WHERE id = ?", arguments: [name, id])
            }
        }
    }

    public func setLocalFolder(id: String, _ name: String?) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET localFolder = ? WHERE id = ?", arguments: [name, id])
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

    public func upsert(_ messages: [StoredMessage]) throws {
        try pool.write { db in
            for m in messages { try m.save(db) }
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
}
