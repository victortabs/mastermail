import Foundation

/// Disponibilidade enviada (ver docs/05-agenda.md): horários livres mandados por e-mail como botões.
/// Cada botão abre uma resposta pronta com a referência `[MM-XXXXXX-n]` no assunto; quando essa resposta
/// chega na Caixa de entrada, o MasterMail cria o evento com convite para a pessoa. Sem servidor próprio.
public struct AvailabilityOffer: Codable, Sendable, Identifiable, Hashable {
    public enum Status: String, Codable, Sendable { case waiting, confirmed, cancelled }

    public var id: String
    /// "Nome <a@b>" ou "a@b".
    public var recipient: String
    public var title: String
    public var durationMinutes: Int
    public var teams: Bool
    public var slots: [Date]
    public var createdAt: Date
    public var status: Status
    public var chosen: Int?

    public init(recipient: String, title: String, durationMinutes: Int, teams: Bool, slots: [Date], createdAt: Date = Date()) {
        id = String((0 ..< 6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })
        self.recipient = recipient; self.title = title; self.durationMinutes = durationMinutes; self.teams = teams
        self.slots = slots.sorted(); self.createdAt = createdAt; status = .waiting
    }

    public var recipientName: String {
        let r = Recipient(parsing: recipient).emailAddress
        return r.name ?? r.address ?? recipient
    }

    public var chosenSlot: Date? { chosen.flatMap { slots.indices.contains($0) ? slots[$0] : nil } }

    public func reference(_ index: Int) -> String { "[MM-\(id)-\(index + 1)]" }

    /// Referência no assunto de uma resposta: id da oferta e índice do horário (base 0).
    public static func match(subject: String) -> (id: String, index: Int)? {
        guard let m = subject.firstMatch(of: /\[MM-([A-Z0-9]{6})-(\d{1,3})\]/), let n = Int(m.2), n > 0 else { return nil }
        return (String(m.1), n - 1)
    }

    public var emailSubject: String { "Horários para \(title)" }

    /// Corpo do e-mail: horários agrupados por dia, cada um um link mailto com a resposta pronta.
    public func emailHTML(replyTo: String) -> String {
        let cal = Calendar.current
        let firstName = recipientName.split(separator: " ").first.map(String.init) ?? recipientName
        let groups = Dictionary(grouping: slots.indices, by: { cal.startOfDay(for: slots[$0]) }).sorted { $0.key < $1.key }
        var html = """
        <div style="font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;font-size:14px;color:#1f2937">
        <p>Olá, \(Self.escape(firstName))!</p>
        <p>Seguem os horários em que posso para <b>\(Self.escape(title))</b> (\(durationMinutes) min\(teams ? ", pelo Teams" : "")).
        Clique no melhor para você: abre uma resposta pronta, é só enviar. O convite chega em seguida.</p>
        """
        for (day, indices) in groups {
            html += "<p style=\"margin:16px 0 6px;font-weight:600\">\(Self.escape(Self.format(day, "EEEE, d 'de' MMMM").capitalizedFirst))</p><p style=\"margin:0\">"
            for i in indices {
                html += "<a href=\"\(mailto(i, replyTo: replyTo))\" style=\"display:inline-block;margin:0 6px 8px 0;padding:6px 14px;border:1px solid #2563eb;border-radius:6px;color:#2563eb;text-decoration:none;font-weight:600\">\(Self.format(slots[i], "HH:mm"))</a>"
            }
            html += "</p>"
        }
        html += """
        <p style="margin-top:18px;color:#6b7280;font-size:12px">Horários em \(Self.escape(TimeZone.current.localizedName(for: .generic, locale: Locale(identifier: "pt_BR")) ?? TimeZone.current.identifier)). \
        Se os botões não abrirem, responda este e-mail com o horário escolhido.</p></div>
        """
        return html
    }

    private func mailto(_ i: Int, replyTo: String) -> String {
        let when = Self.format(slots[i], "EEEE, d 'de' MMMM 'às' HH:mm")
        let subject = "Confirmado: \(title) — \(Self.format(slots[i], "EEE dd/MM HH:mm")) \(reference(i))"
        let body = "Confirmo \(title) na \(when)."
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        func enc(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: allowed) ?? "" }
        return "mailto:\(enc(replyTo).replacingOccurrences(of: "%40", with: "@"))?subject=\(enc(subject))&body=\(enc(body))"
    }

    private static func format(_ date: Date, _ pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.timeZone = .current
        f.dateFormat = pattern
        return f.string(from: date)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

public enum Availability {
    /// Inícios de horários livres: blocos de `duration` a cada `step`, dentro do expediente de cada dia,
    /// sem encostar em nenhum intervalo ocupado e começando pelo menos 1 h depois de `now`.
    public static func freeSlots(days: [Date], busy: [DateInterval], workStart: Int, workEnd: Int,
                                 duration: TimeInterval, step: TimeInterval, now: Date, calendar: Calendar = .current) -> [Date] {
        let earliest = now.addingTimeInterval(3600)
        var result: [Date] = []
        for day in days {
            guard let open = calendar.date(bySettingHour: workStart, minute: 0, second: 0, of: day),
                  let close = calendar.date(bySettingHour: workEnd, minute: 0, second: 0, of: day) else { continue }
            var start = open
            while start.addingTimeInterval(duration) <= close {
                let end = start.addingTimeInterval(duration)
                if start >= earliest, !busy.contains(where: { $0.start < end && $0.end > start }) { result.append(start) }
                start = start.addingTimeInterval(step)
            }
        }
        return result
    }

    /// Próximos `count` dias a partir de hoje, pulando sábado e domingo se `weekdaysOnly`.
    public static func days(from date: Date, count: Int, weekdaysOnly: Bool, calendar: Calendar = .current) -> [Date] {
        var days: [Date] = []
        var d = calendar.startOfDay(for: date)
        while days.count < count {
            if !weekdaysOnly || !calendar.isDateInWeekend(d) { days.append(d) }
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }
        return days
    }
}

/// Ofertas enviadas, em JSON no Application Support (como o plano do Organizador).
public struct AvailabilityStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public static func `default`() -> AvailabilityStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return AvailabilityStore(fileURL: base.appendingPathComponent("MasterMail/availability.json"))
    }

    public func load() -> [AvailabilityOffer] {
        (try? Data(contentsOf: fileURL)).flatMap { try? JSONDecoder().decode([AvailabilityOffer].self, from: $0) } ?? []
    }

    public func save(_ offers: [AvailabilityOffer]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(offers).write(to: fileURL, options: .atomic)
    }
}

public extension GraphClient {
    /// Envia direto (sem rascunho): usado pela Disponibilidade, que já mostra tudo antes de enviar.
    func sendMail(to recipients: [Recipient], subject: String, html: String) async throws {
        struct Payload: Encodable {
            struct Message: Encodable { var subject: String; var body: ItemBody; var toRecipients: [Recipient] }
            var message: Message
            var saveToSentItems = true
        }
        let payload = Payload(message: .init(subject: subject, body: ItemBody(contentType: "html", content: html), toRecipients: recipients))
        try await post("me/sendMail", json: JSONEncoder().encode(payload))
    }
}

public extension CalendarEvent {
    /// Link do Teams de trabalho no esquema do app (`msteams:`), para abrir direto sem passar pelo navegador.
    /// nil para outros links (Teams pessoal, Zoom, Meet…), que seguem pelo navegador.
    static func teamsAppURL(for url: URL) -> URL? {
        let prefix = "https://teams.microsoft.com/"
        guard url.absoluteString.lowercased().hasPrefix(prefix) else { return nil }
        return URL(string: "msteams:/" + url.absoluteString.dropFirst(prefix.count))
    }
}
