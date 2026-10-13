import Foundation
import GRDB

/// Organização (ver CONTEXT.md): os Contatos que compartilham o domínio. Nasce das mensagens; o usuário renomeia e funde.
public struct Organization: Identifiable, Sendable, Hashable {
    public var id: String { domain }
    public var domain: String
    public var name: String
    public var messageCount: Int
    public var contactCount: Int
    public var lastDate: Date?

    /// Domínios que não formam Organização (CONTEXT.md).
    public static let publicDomains: Set<String> = [
        "gmail.com", "outlook.com", "hotmail.com", "live.com", "yahoo.com", "icloud.com", "me.com",
        "uol.com.br", "bol.com.br", "terra.com.br", "globo.com", "msn.com", "protonmail.com", "proton.me",
    ]

    /// Nome padrão: primeiro rótulo do domínio, capitalizado ("bdil.com.br" → "Bdil").
    static func defaultName(_ domain: String) -> String {
        String(domain.split(separator: ".").first ?? Substring(domain)).capitalized
    }
}

/// Contato (ver CONTEXT.md): uma pessoa identificada pelo endereço. Linha da tabela derivada `contact`.
public struct Contact: Identifiable, Sendable, Hashable, Codable, FetchableRecord {
    public static let databaseTableName = "contact"

    public var id: String { address }
    public var address: String
    public var name: String
    public var domain: String
    public var messageCount: Int
    public var lastDate: Date?
    public var isSaved: Bool

    public var display: String { name.isEmpty ? address : "\(name) <\(address)>" }

    static func domain(of address: String) -> String? {
        guard let at = address.lastIndex(of: "@") else { return nil }
        let d = address[address.index(after: at)...].trimmingCharacters(in: .whitespaces).lowercased()
        return d.isEmpty ? nil : d
    }
}

public extension MailStore {
    // ponytail: Contatos e Organizações vivem em tabelas derivadas (`contact`, `organization`) recalculadas por
    // `refreshPeople` numa passada sobre o índice (só 4 colunas, ~1 s a 100k mensagens), porque `recipients` é texto
    // livre que o SQL não agrupa. Se ficar lento, atualizar incrementalmente no upsert do MailSync.
    static func migratePeople(_ db: Database) throws {
        try db.create(table: "organization") { t in
            t.primaryKey("domain", .text)
            t.column("name", .text)
            t.column("mergedInto", .text)
            t.column("messageCount", .integer).notNull().defaults(to: 0)
            t.column("lastDate", .datetime)
        }
        try db.create(table: "contact") { t in
            t.primaryKey("address", .text)
            t.column("name", .text).notNull().defaults(to: "")
            t.column("domain", .text).notNull().indexed()
            t.column("messageCount", .integer).notNull().defaults(to: 0)
            t.column("lastDate", .datetime)
            t.column("isSaved", .boolean).notNull().defaults(to: false)
        }
    }

    /// Recalcula Contatos (remetentes + destinatários) e contagens por domínio a partir do índice. `me` fica de fora.
    func refreshPeople(me: String) throws {
        struct Agg { var name = ""; var count = 0; var last: Date? }
        var contacts: [String: Agg] = [:]
        var domains: [String: Agg] = [:]
        let me = me.lowercased()
        try pool.read { db in
            let rows = try Row.fetchCursor(db, sql: "SELECT fromName, fromAddress, recipients, receivedAt FROM message")
            while let row = try rows.next() {
                let date: Date = row["receivedAt"]
                var people = Recipient.parseList(row["recipients"]).map { ($0.emailAddress.name ?? "", $0.emailAddress.address ?? "") }
                people.append((row["fromName"], row["fromAddress"]))
                var touched = Set<String>()
                for (name, rawAddress) in people {
                    let address = rawAddress.trimmingCharacters(in: .whitespaces).lowercased()
                    guard address != me, let domain = Contact.domain(of: address) else { continue }
                    var agg = contacts[address] ?? Agg()
                    agg.count += 1
                    if agg.last.map({ date > $0 }) ?? true {
                        agg.last = date
                        if !name.isEmpty { agg.name = name }
                    }
                    contacts[address] = agg
                    touched.insert(domain)
                }
                for domain in touched where !Organization.publicDomains.contains(domain) {
                    var agg = domains[domain] ?? Agg()
                    agg.count += 1
                    agg.last = max(agg.last ?? date, date)
                    domains[domain] = agg
                }
            }
        }
        try pool.write { db in
            try db.execute(sql: "UPDATE contact SET messageCount = 0, lastDate = NULL")
            try db.execute(sql: "UPDATE organization SET messageCount = 0, lastDate = NULL")
            for (address, agg) in contacts {
                try db.execute(sql: """
                    INSERT INTO contact(address, name, domain, messageCount, lastDate, isSaved) VALUES (?, ?, ?, ?, ?, 0)
                    ON CONFLICT(address) DO UPDATE SET messageCount = excluded.messageCount, lastDate = excluded.lastDate,
                        name = CASE WHEN excluded.name = '' THEN name ELSE excluded.name END
                    """, arguments: [address, agg.name, Contact.domain(of: address)!, agg.count, agg.last])
            }
            for (domain, agg) in domains {
                try db.execute(sql: """
                    INSERT INTO organization(domain, messageCount, lastDate) VALUES (?, ?, ?)
                    ON CONFLICT(domain) DO UPDATE SET messageCount = excluded.messageCount, lastDate = excluded.lastDate
                    """, arguments: [domain, agg.count, agg.last])
            }
            try db.execute(sql: "DELETE FROM contact WHERE messageCount = 0 AND isSaved = 0")
        }
    }

    /// Contatos salvos na conta (Graph). Quem não está na lista perde a marca.
    func markSaved(_ saved: [(name: String, address: String)]) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE contact SET isSaved = 0")
            for (name, rawAddress) in saved {
                let address = rawAddress.trimmingCharacters(in: .whitespaces).lowercased()
                guard let domain = Contact.domain(of: address) else { continue }
                try db.execute(sql: """
                    INSERT INTO contact(address, name, domain, messageCount, lastDate, isSaved) VALUES (?, ?, ?, 0, NULL, 1)
                    ON CONFLICT(address) DO UPDATE SET isSaved = 1, name = CASE WHEN name = '' THEN excluded.name ELSE name END
                    """, arguments: [address, name, domain])
                if !Organization.publicDomains.contains(domain) {
                    try db.execute(sql: "INSERT OR IGNORE INTO organization(domain) VALUES (?)", arguments: [domain])
                }
            }
        }
    }

    /// Organizações com mensagens ou Contatos, mais ativas primeiro. Domínios fundidos somam no destino.
    func organizations() throws -> [Organization] {
        try pool.read { db in
            let names = try Dictionary(uniqueKeysWithValues: Row.fetchAll(db, sql: "SELECT domain, name FROM organization WHERE name IS NOT NULL")
                .map { ($0["domain"] as String, $0["name"] as String) })
            return try Row.fetchAll(db, sql: """
                SELECT COALESCE(o.mergedInto, o.domain) AS domain, SUM(o.messageCount) AS messageCount,
                       SUM(COALESCE(cc.n, 0)) AS contactCount, MAX(o.lastDate) AS lastDate
                FROM organization o
                LEFT JOIN (SELECT domain, COUNT(*) AS n FROM contact GROUP BY domain) cc ON cc.domain = o.domain
                GROUP BY 1 HAVING messageCount > 0 OR contactCount > 0
                ORDER BY messageCount DESC, domain
                """).map { row in
                let domain: String = row["domain"]
                return Organization(domain: domain, name: names[domain] ?? Organization.defaultName(domain),
                                    messageCount: row["messageCount"], contactCount: row["contactCount"], lastDate: row["lastDate"])
            }
        }
    }

    func renameOrganization(domain: String, name: String) throws {
        let name = name.trimmingCharacters(in: .whitespaces)
        try pool.write { db in
            try db.execute(sql: "INSERT INTO organization(domain, name) VALUES (?, ?) ON CONFLICT(domain) DO UPDATE SET name = excluded.name",
                           arguments: [domain, name.isEmpty ? nil : name])
        }
    }

    /// Funde `domain` em `target` (segue fusões anteriores de `target`; quem apontava para `domain` passa a apontar para o destino).
    func mergeOrganization(domain: String, into target: String) throws {
        try pool.write { db in
            let final = try String.fetchOne(db, sql: "SELECT mergedInto FROM organization WHERE domain = ? AND mergedInto IS NOT NULL", arguments: [target]) ?? target
            guard final != domain else { return }
            try db.execute(sql: "INSERT INTO organization(domain, mergedInto) VALUES (?, ?) ON CONFLICT(domain) DO UPDATE SET mergedInto = excluded.mergedInto",
                           arguments: [domain, final])
            try db.execute(sql: "UPDATE organization SET mergedInto = ? WHERE mergedInto = ?", arguments: [final, domain])
        }
    }

    /// Contatos de uma Organização (inclui domínios fundidos nela); nil = todos.
    func contacts(domain: String? = nil) throws -> [Contact] {
        try pool.read { db in
            try Contact.fetchAll(db, sql: """
                SELECT * FROM contact WHERE ? IS NULL OR domain = ? OR domain IN (SELECT domain FROM organization WHERE mergedInto = ?)
                ORDER BY messageCount DESC, name
                """, arguments: [domain, domain, domain])
        }
    }

    /// Mensagens trocadas com a Organização: remetente ou algum destinatário no domínio (ou num fundido nele).
    // ponytail: LIKE '%@dominio' varre a tabela inteira; a 100k mensagens ainda é < 1 s. Se doer, indexar o domínio do remetente.
    func messages(domain: String, limit: Int = 300, offset: Int = 0) throws -> [StoredMessage] {
        try pool.read { db in
            let domains = [domain] + (try String.fetchAll(db, sql: "SELECT domain FROM organization WHERE mergedInto = ?", arguments: [domain]))
            let clauses = domains.map { _ in "(fromAddress LIKE ? OR recipients LIKE ? OR recipients LIKE ? OR recipients LIKE ?)" }
            let arguments = domains.flatMap { ["%@\($0)", "%@\($0)>%", "%@\($0),%", "%@\($0)"] }
            return try StoredMessage.fetchAll(db, sql: """
                SELECT * FROM message WHERE \(clauses.joined(separator: " OR ")) ORDER BY receivedAt DESC LIMIT ? OFFSET ?
                """, arguments: StatementArguments(arguments + [limit, offset]))
        }
    }

    /// Autocompletar de destinatário: nome (qualquer palavra) ou endereço começando por `prefix`, mais frequentes primeiro.
    func suggestRecipients(prefix: String, limit: Int = 8) throws -> [Contact] {
        let p = prefix.trimmingCharacters(in: .whitespaces)
        guard !p.isEmpty else { return [] }
        let escaped = p.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "%", with: "\\%").replacingOccurrences(of: "_", with: "\\_")
        return try pool.read { db in
            try Contact.fetchAll(db, sql: """
                SELECT * FROM contact
                WHERE name LIKE ? ESCAPE '\\' OR name LIKE ? ESCAPE '\\' OR address LIKE ? ESCAPE '\\'
                ORDER BY messageCount DESC, name LIMIT ?
                """, arguments: ["\(escaped)%", "% \(escaped)%", "\(escaped)%", limit])
        }
    }
}

public extension GraphClient {
    /// Contatos salvos na conta: nome e cada endereço.
    func savedContacts() async throws -> [(name: String, address: String)] {
        struct GraphContact: Decodable, Sendable {
            var displayName: String?
            var emailAddresses: [EmailAddress]?
        }
        var result: [(name: String, address: String)] = []
        var url: URL? = {
            var c = URLComponents(url: Self.baseURL.appendingPathComponent("me/contacts"), resolvingAgainstBaseURL: false)!
            c.queryItems = [.init(name: "$select", value: "displayName,emailAddresses"), .init(name: "$top", value: "500")]
            return c.url
        }()
        while let next = url {
            let page: GraphPage<GraphContact> = try await get(url: next)
            for c in page.value {
                for e in c.emailAddresses ?? [] {
                    if let address = e.address, !address.isEmpty { result.append((c.displayName ?? e.name ?? "", address)) }
                }
            }
            url = page.nextLink
        }
        return result
    }
}
