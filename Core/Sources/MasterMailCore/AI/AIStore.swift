import Foundation
import GRDB

/// Migração "ai-1" e consultas da camada de IA sobre o Índice local.
extension MailStore {
    static func registerAIMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("ai-1") { db in
            try db.alter(table: "message") { t in
                t.add(column: "tipo", .text).indexed()
                t.add(column: "importante", .boolean).notNull().defaults(to: false)
                t.add(column: "justificativa", .text)
                t.add(column: "classifiedAt", .datetime)
                t.add(column: "triagemConfirmada", .boolean).notNull().defaults(to: false)
            }
            try db.create(table: "rule") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("field", .text).notNull()
                t.column("value", .text).notNull()
                t.column("tipo", .text)
                t.column("categoria", .text)
                t.column("pastaLocal", .text)
                t.column("automatic", .boolean).notNull().defaults(to: false)
                t.column("explanation", .text)
                t.column("hits", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
            }
        }
    }

    private static let ruidoSQL = "tipo IN (" + Tipo.ruido.map { "'\($0)'" }.joined(separator: ",") + ")"

    // MARK: Classificação

    /// Mensagens da pasta ainda sem Tipo, mais recentes primeiro.
    public func unclassified(in folder: String, limit: Int = 50) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(Column("folder") == folder && Column("classifiedAt") == nil)
                .order(Column("receivedAt").desc).limit(limit).fetchAll(db)
        }
    }

    /// Grava o resultado. `byRule` só anota na Justificativa de onde veio.
    public func saveClassification(id: String, _ c: Classification, byRule: Bool = false) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET tipo = ?, importante = ?, justificativa = ?, classifiedAt = ? WHERE id = ?",
                           arguments: [c.tipo.rawValue, c.importante, byRule ? "Regra: " + c.justificativa : c.justificativa, Date(), id])
        }
    }

    public func confirmTriage(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET triagemConfirmada = 1 WHERE id = ?", arguments: [id])
        }
    }

    /// Triagem (CONTEXT.md): Ruído ainda não confirmado, fora de Pasta local.
    public func triage(folder: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(sql: "folder = ? AND localFolder IS NULL AND triagemConfirmada = 0 AND \(Self.ruidoSQL)", arguments: [folder])
                .order(Column("receivedAt").desc).limit(limit, offset: offset).fetchAll(db)
        }
    }

    /// Caixa de entrada (CONTEXT.md): fora de Pasta local e não Ruído (sem Tipo ainda conta como entrada).
    public func inboxMessages(folder: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(sql: "folder = ? AND localFolder IS NULL AND (snoozedUntil IS NULL OR snoozedUntil <= ?) AND (tipo IS NULL OR NOT \(Self.ruidoSQL))", arguments: [folder, Date()])
                .order(Column("receivedAt").desc).limit(limit, offset: offset).fetchAll(db)
        }
    }

    /// Todo o Ruído da pasta, confirmado ou não (para nada se perder de vista).
    public func noise(folder: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(sql: "folder = ? AND localFolder IS NULL AND \(Self.ruidoSQL)", arguments: [folder])
                .order(Column("receivedAt").desc).limit(limit, offset: offset).fetchAll(db)
        }
    }

    public func triageCount(folder: String) throws -> Int {
        try pool.read { db in
            try Int.fetchOne(db, sql: "SELECT count(*) FROM message WHERE folder = ? AND localFolder IS NULL AND triagemConfirmada = 0 AND \(Self.ruidoSQL)", arguments: [folder]) ?? 0
        }
    }

    /// O usuário discordou: vira Pessoa, sai da Triagem e volta à Caixa de entrada.
    public func markNotNoise(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET tipo = 'pessoa', triagemConfirmada = 1 WHERE id = ?", arguments: [id])
        }
    }

    /// Mensagens recebidas hoje na pasta (contador do Dock).
    public func receivedToday(folder: String) throws -> Int {
        try pool.read { db in
            try Int.fetchOne(db, sql: "SELECT count(*) FROM message WHERE folder = ? AND receivedAt >= ?", arguments: [folder, Calendar.current.startOfDay(for: Date())]) ?? 0
        }
    }

    /// Importantes não lidas: a única fonte de notificação do Mac.
    public func importantUnread(limit: Int = 50) throws -> [StoredMessage] {
        try pool.read { db in
            try StoredMessage.filter(Column("importante") == true && Column("isRead") == false)
                .order(Column("receivedAt").desc).limit(limit).fetchAll(db)
        }
    }

    // MARK: Regras

    public func rules() throws -> [Rule] {
        try pool.read { db in try Rule.order(Column("createdAt").desc).fetchAll(db) }
    }

    @discardableResult
    public func saveRule(_ rule: Rule) throws -> Rule {
        try pool.write { db in
            var r = rule
            try r.save(db)
            return r
        }
    }

    public func deleteRule(id: Int64) throws {
        try pool.write { db in _ = try Rule.deleteOne(db, key: id) }
    }

    func countRuleHit(id: Int64) throws {
        try pool.write { db in try db.execute(sql: "UPDATE rule SET hits = hits + 1 WHERE id = ?", arguments: [id]) }
    }
}
