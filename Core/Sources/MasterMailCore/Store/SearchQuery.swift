import Foundation
import GRDB

/// Busca com operadores (requisito): `from:`, `to:`, `org:`, `has:attachment`, `before:`, `after:`, `in:<pasta local>`.
public struct SearchQuery: Equatable, Sendable {
    public var text = ""
    public var from: String?
    public var to: String?
    public var org: String?
    public var hasAttachment = false
    public var after: Date?
    public var before: Date?
    public var localFolder: String?

    public init() {}

    public static func parse(_ raw: String) -> SearchQuery {
        var q = SearchQuery()
        var words: [String] = []
        for token in raw.matches(of: /(?:[^\s"]+|"[^"]*")+/) {
            let t = String(token.output)
            guard let colon = t.firstIndex(of: ":"), colon != t.startIndex else { words.append(t); continue }
            let key = t[..<colon].lowercased()
            let value = String(t[t.index(after: colon)...]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            guard !value.isEmpty else { words.append(t); continue }
            switch key {
            case "from", "de": q.from = value
            case "to", "para": q.to = value
            case "org": q.org = value
            case "has", "tem": if ["attachment", "attachments", "anexo", "anexos"].contains(value.lowercased()) { q.hasAttachment = true } else { words.append(t) }
            case "after", "depois": if let date = Self.date(value) { q.after = date } else { words.append(t) }
            case "before", "antes": if let date = Self.date(value) { q.before = date } else { words.append(t) }
            case "in", "em": q.localFolder = value.replacingOccurrences(of: "_", with: " ")
            default: words.append(t)
            }
        }
        q.text = words.joined(separator: " ")
        return q
    }

    static func date(_ s: String) -> Date? {
        for format in ["yyyy-MM-dd", "dd/MM/yyyy", "dd/MM/yy", "yyyy-MM", "yyyy"] {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = format
            if let d = f.date(from: s) { return d }
        }
        return nil
    }

    public var hasOperators: Bool { from != nil || to != nil || org != nil || hasAttachment || after != nil || before != nil || localFolder != nil }

    public var isEmpty: Bool { text.isEmpty && from == nil && to == nil && org == nil && !hasAttachment && after == nil && before == nil && localFolder == nil }
}

public extension MailStore {
    /// Busca com operadores. Sem texto, filtra o índice inteiro só pelos operadores.
    func search(_ q: SearchQuery, limit: Int = 200) throws -> [StoredMessage] {
        guard !q.isEmpty else { return [] }
        var conditions: [String] = []
        var args: [DatabaseValueConvertible] = []
        if let from = q.from { conditions.append("(lower(message.fromAddress) LIKE ? OR lower(message.fromName) LIKE ?)"); args += ["%\(from.lowercased())%", "%\(from.lowercased())%"] }
        if let to = q.to { conditions.append("lower(message.recipients) LIKE ?"); args.append("%\(to.lowercased())%") }
        if let org = q.org { conditions.append("(lower(message.fromAddress) LIKE ? OR lower(message.recipients) LIKE ?)"); args += ["%@%\(org.lowercased())%", "%@%\(org.lowercased())%"] }
        if q.hasAttachment { conditions.append("message.hasAttachments = 1") }
        if let after = q.after { conditions.append("message.receivedAt >= ?"); args.append(after) }
        if let before = q.before { conditions.append("message.receivedAt < ?"); args.append(before) }
        if let folder = q.localFolder { conditions.append("lower(message.localFolder) = ?"); args.append(folder.lowercased()) }
        let whereSQL = conditions.isEmpty ? "1" : conditions.joined(separator: " AND ")
        return try pool.read { db in
            if q.text.isEmpty {
                return try StoredMessage.fetchAll(db, sql: "SELECT * FROM message WHERE \(whereSQL) ORDER BY receivedAt DESC LIMIT ?", arguments: StatementArguments(args + [limit]))
            }
            guard let pattern = FTS5Pattern(matchingAllPrefixesIn: q.text) else { return [] }
            return try StoredMessage.fetchAll(db, sql: """
                SELECT message.* FROM message
                JOIN message_ft ON message_ft.rowid = message.rowid
                WHERE message_ft MATCH ? AND \(whereSQL)
                ORDER BY bm25(message_ft, 10.0, 5.0, 5.0, 2.0, 1.0), message.receivedAt DESC
                LIMIT ?
                """, arguments: StatementArguments([pattern] + args + [limit]))
        }
    }
}
