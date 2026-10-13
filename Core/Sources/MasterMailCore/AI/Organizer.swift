import Foundation
import GRDB

/// Perfil agregado da caixa: só contagens e amostras de assunto, nunca corpos. É o que vai para o modelo.
public struct MailboxProfile: Sendable {
    public struct Sender: Sendable {
        public var domain: String
        public var count: Int
        public var readPercent: Int
        public var repliedTo: Int
        public var sampleSubjects: [String]
    }

    public var total: Int
    public var unread: Int
    public var since: Date?
    public var senders: [Sender]

    public var text: String {
        var lines = ["Caixa com \(total) mensagens (\(unread) não lidas) desde \(since.map { Assistant.dayFormatter.string(from: $0) } ?? "?")."]
        lines.append("domínio | mensagens | % lidas | vezes que o usuário escreveu para o domínio | assuntos de exemplo")
        for s in senders {
            lines.append("\(s.domain) | \(s.count) | \(s.readPercent)% | \(s.repliedTo) | \(s.sampleSubjects.joined(separator: " / "))")
        }
        return lines.joined(separator: "\n")
    }
}

/// O que o Organizador propõe. Nada acontece sem o usuário aceitar (Sugestão, CONTEXT.md).
public struct OrganizationPlan: Codable, Sendable, Equatable {
    public struct RuleProposal: Codable, Sendable, Equatable, Identifiable {
        public var id: String { "\(field):\(value)" }
        public var field: String      // sender | domain | subjectContains
        public var value: String
        public var tipo: String       // pessoa | newsletter | notificacao | promocao | financeiro | convite
        public var pastaLocal: String?
        public var reason: String
    }

    public struct FolderProposal: Codable, Sendable, Equatable, Identifiable {
        public var id: String { name }
        public var name: String
        public var description: String
        public var domains: [String]
    }

    public var rules: [RuleProposal]
    public var folders: [FolderProposal]
    public var categories: [String]
    public var summary: String

    public init(rules: [RuleProposal] = [], folders: [FolderProposal] = [], categories: [String] = [], summary: String = "") {
        self.rules = rules; self.folders = folders; self.categories = categories; self.summary = summary
    }
}

public extension MailStore {
    /// Agrega os remetentes da pasta por domínio. `sentFolder` serve para saber se o usuário escreve para o domínio.
    func profile(inbox: String, sent: String?, limit: Int = 60) throws -> MailboxProfile {
        try pool.read { db in
            let total = try Int.fetchOne(db, sql: "SELECT count(*) FROM message WHERE folder = ?", arguments: [inbox]) ?? 0
            let unread = try Int.fetchOne(db, sql: "SELECT count(*) FROM message WHERE folder = ? AND isRead = 0", arguments: [inbox]) ?? 0
            let since = try Date.fetchOne(db, sql: "SELECT min(receivedAt) FROM message WHERE folder = ?", arguments: [inbox])
            let rows = try Row.fetchAll(db, sql: """
                SELECT lower(substr(fromAddress, instr(fromAddress, '@') + 1)) AS dom, count(*) AS n,
                       round(100.0 * sum(isRead) / count(*)) AS readPct,
                       group_concat(DISTINCT substr(subject, 1, 40)) AS subjects
                FROM message WHERE folder = ? AND fromAddress LIKE '%@%'
                GROUP BY dom ORDER BY n DESC LIMIT ?
                """, arguments: [inbox, limit])
            var senders: [MailboxProfile.Sender] = []
            for row in rows {
                let dom: String = row["dom"]
                var replied = 0
                if let sent {
                    replied = try Int.fetchOne(db, sql: "SELECT count(*) FROM message WHERE folder = ? AND lower(recipients) LIKE ?", arguments: [sent, "%@\(dom)%"]) ?? 0
                }
                let subjects = ((row["subjects"] as String?) ?? "").split(separator: ",").prefix(3).map { String($0).trimmingCharacters(in: .whitespaces) }
                senders.append(.init(domain: dom, count: row["n"], readPercent: Int(row["readPct"] as Double? ?? 0), repliedTo: replied, sampleSubjects: subjects))
            }
            return MailboxProfile(total: total, unread: unread, since: since, senders: senders)
        }
    }
}

/// Guarda o plano proposto (pelo modelo ou por um agente externo) até o usuário revisar no app.
public struct OrganizationPlanStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public static func `default`() -> OrganizationPlanStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return OrganizationPlanStore(fileURL: base.appendingPathComponent("MasterMail/organization-plan.json"))
    }

    public func load() -> OrganizationPlan? {
        (try? Data(contentsOf: fileURL)).flatMap { try? JSONDecoder().decode(OrganizationPlan.self, from: $0) }
    }

    public func save(_ plan: OrganizationPlan) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(plan).write(to: fileURL, options: .atomic)
    }

    public func clear() { try? FileManager.default.removeItem(at: fileURL) }
}

/// Organizador: lê o perfil da caixa e propõe Regras de ruído, Pastas locais e Categorias. Roda com o modelo que o usuário escolher.
public struct Organizer: Sendable {
    public let provider: AIProvider

    public init(provider: AIProvider) { self.provider = provider }

    public func propose(from profile: MailboxProfile) async throws -> OrganizationPlan {
        let raw = try await provider.complete(system: Prompts.organizer, user: profile.text, maxTokens: 4000)
        return try Self.parse(raw)
    }

    static func parse(_ raw: String) throws -> OrganizationPlan {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"), start < end else {
            throw AIError.badResponse(String(raw.prefix(200)))
        }
        return try JSONDecoder().decode(OrganizationPlan.self, from: Data(raw[start...end].utf8))
    }
}

public extension MailStore {
    /// Classifica na hora, no índice inteiro, o que a regra cobre (zero tokens). Regra automática já confirma o Ruído.
    func applyToIndex(_ rule: Rule) throws {
        guard let tipo = rule.tipo else { return }
        let confirmed = rule.automatic && (Tipo(rawValue: tipo)?.isRuido ?? false)
        let why = "Regra: " + (rule.explanation ?? "\(rule.field.rawValue) = \(rule.value)")
        let (whereSQL, arg): (String, String) = switch rule.field {
        case .sender: ("lower(fromAddress) = ?", rule.value)
        case .domain: ("lower(fromAddress) LIKE ?", "%@" + rule.value)
        case .subjectContains: ("lower(subject) LIKE ?", "%" + rule.value + "%")
        }
        try pool.write { db in
            try db.execute(sql: "UPDATE message SET tipo = ?, justificativa = ?, classifiedAt = ?, triagemConfirmada = ? WHERE \(whereSQL)",
                           arguments: [tipo, why, Date(), confirmed, arg])
        }
    }

    /// Aplica o que o usuário aceitou: Regras (não automáticas), Pastas locais e, opcionalmente, move o que já casa com as regras de pasta.
    /// Devolve os ids que mudaram de Pasta local (para gravar no servidor).
    func apply(_ plan: OrganizationPlan, moveExisting: Bool, automatic: Bool = true) throws -> [(id: String, folder: String)] {
        for f in plan.folders { try createLocalFolder(f.name) }
        var moved: [(String, String)] = []
        for r in plan.rules {
            guard let field = Rule.Field(rawValue: r.field) else { continue }
            let rule = Rule(field: field, value: r.value.lowercased(), tipo: Tipo(lenient: r.tipo), pastaLocal: r.pastaLocal, automatic: automatic, explanation: r.reason)
            try saveRule(rule)
            try applyToIndex(rule)
            if moveExisting, let folder = r.pastaLocal {
                let ids: [String] = try pool.read { db in
                    switch field {
                    case .sender: try String.fetchAll(db, sql: "SELECT id FROM message WHERE lower(fromAddress) = ? AND localFolder IS NULL", arguments: [r.value.lowercased()])
                    case .domain: try String.fetchAll(db, sql: "SELECT id FROM message WHERE lower(fromAddress) LIKE ? AND localFolder IS NULL", arguments: ["%@" + r.value.lowercased()])
                    case .subjectContains: try String.fetchAll(db, sql: "SELECT id FROM message WHERE lower(subject) LIKE ? AND localFolder IS NULL", arguments: ["%" + r.value.lowercased() + "%"])
                    }
                }
                for id in ids { try setLocalFolder(id: id, folder); moved.append((id, folder)) }
            }
        }
        return moved
    }
}
