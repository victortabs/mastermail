import Foundation

/// Evento de agenda, da Agenda Microsoft (editável) ou da Agenda do Mac (só leitura). Ver CONTEXT.md.
public struct CalendarEvent: Identifiable, Sendable, Hashable {
    public enum Source: Sendable, Hashable { case microsoft, mac(calendar: String) }

    /// Convidado de uma reunião e a resposta dele (accepted, tentativelyAccepted, declined, notResponded, none).
    public struct Invitee: Sendable, Hashable {
        public var name: String
        public var address: String?
        public var response: String?
        public var isOptional: Bool

        public init(name: String, address: String? = nil, response: String? = nil, isOptional: Bool = false) {
            self.name = name; self.address = address; self.response = response; self.isOptional = isOptional
        }
    }

    public var id: String
    public var source: Source
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var location: String?
    public var organizer: String?
    public var attendees: [Invitee]
    public var webLink: URL?
    public var isCancelled: Bool
    /// Resposta do usuário na Agenda Microsoft: accepted, tentativelyAccepted, declined, notResponded, organizer, none.
    public var response: String?
    public var bodyPreview: String?
    /// Cor do calendário de origem ("#RRGGBB"); nil = cor padrão da Agenda Microsoft.
    public var colorHex: String?
    /// free, tentative, busy, oof, workingElsewhere.
    public var showAs: String?
    /// Link para entrar na reunião online (Teams, Zoom, Meet…).
    public var joinURL: URL?
    /// Ocorrência de uma série: id da série no Graph.
    public var seriesMasterID: String?
    /// Alerta em minutos antes do início; nil = sem alerta.
    public var reminderMinutes: Int?

    public var isEditable: Bool { if case .microsoft = source { return true } else { return false } }
    public var isRecurring: Bool { seriesMasterID != nil }
    /// Pode mudar título, horário e convidados: evento próprio na Agenda Microsoft (convidado só responde).
    public var canEdit: Bool { isEditable && !isCancelled && (response == "organizer" || response == "none" || response == nil || attendees.isEmpty) }

    public init(id: String, source: Source, title: String, start: Date, end: Date, isAllDay: Bool, location: String? = nil, organizer: String? = nil,
                attendees: [Invitee] = [], webLink: URL? = nil, isCancelled: Bool = false, response: String? = nil, bodyPreview: String? = nil,
                colorHex: String? = nil, showAs: String? = nil, joinURL: URL? = nil, seriesMasterID: String? = nil, reminderMinutes: Int? = nil) {
        self.id = id; self.source = source; self.title = title; self.start = start; self.end = end; self.isAllDay = isAllDay
        self.location = location; self.organizer = organizer; self.attendees = attendees; self.webLink = webLink
        self.isCancelled = isCancelled; self.response = response; self.bodyPreview = bodyPreview
        self.colorHex = colorHex; self.showAs = showAs; self.joinURL = joinURL ?? Self.meetingLink(in: [location, bodyPreview])
        self.seriesMasterID = seriesMasterID; self.reminderMinutes = reminderMinutes
    }

    /// Primeiro link de reunião online achado no texto (local, corpo).
    public static func meetingLink(in texts: [String?]) -> URL? {
        let pattern = /https:\/\/[^\s<>"']*?(?:teams\.microsoft\.com|teams\.live\.com|zoom\.us|meet\.google\.com|webex\.com|whereby\.com)[^\s<>"']*/
        for text in texts.compactMap({ $0 }) {
            if let match = text.firstMatch(of: pattern), let url = URL(string: String(match.0)) { return url }
        }
        return nil
    }
}

/// Repetição oferecida no editor. `custom` = série criada em outro app com regra que o MasterMail não edita (fica como está).
public enum EventRepeat: String, CaseIterable, Sendable, Hashable {
    case none, daily, weekdays, weekly, monthly, yearly, custom

    public var label: String {
        switch self {
        case .none: "Não se repete"
        case .daily: "Todo dia"
        case .weekdays: "Dias úteis (seg–sex)"
        case .weekly: "Toda semana"
        case .monthly: "Todo mês"
        case .yearly: "Todo ano"
        case .custom: "Personalizada (mantida)"
        }
    }
}

/// Detalhes que a grade não carrega: corpo em texto e regra de repetição (para editar).
public struct EventDetails: Sendable {
    public var event: CalendarEvent
    public var notes: String
    public var repeatRule: EventRepeat
    public var repeatUntil: Date?
    public var isOnlineMeeting: Bool

    public init(event: CalendarEvent, notes: String, repeatRule: EventRepeat, repeatUntil: Date?, isOnlineMeeting: Bool) {
        self.event = event; self.notes = notes; self.repeatRule = repeatRule; self.repeatUntil = repeatUntil; self.isOnlineMeeting = isOnlineMeeting
    }
}

// MARK: Graph

struct GraphDateTime: Codable, Sendable {
    var dateTime: String
    var timeZone: String

    /// O Graph devolve "2026-10-13T09:00:00.0000000" no fuso pedido (Prefer: outlook.timezone).
    var date: Date? {
        let trimmed = dateTime.replacing(/\.\d+$/, with: "")
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: timeZone) ?? .current
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return fmt.date(from: trimmed)
    }

    static func make(_ date: Date) -> GraphDateTime {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return GraphDateTime(dateTime: fmt.string(from: date), timeZone: TimeZone.current.identifier)
    }
}

/// `recurrence` do Graph (patternedRecurrence).
struct GraphRecurrence: Codable, Sendable {
    struct Pattern: Codable, Sendable {
        var type: String
        var interval: Int
        var daysOfWeek: [String]?
        var dayOfMonth: Int?
        var month: Int?
        var firstDayOfWeek: String?
    }
    struct Range: Codable, Sendable {
        var type: String
        var startDate: String
        var endDate: String?
    }
    var pattern: Pattern
    var range: Range

    private static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    private static let workdays = ["monday", "tuesday", "wednesday", "thursday", "friday"]

    private static func day(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    static func make(_ rule: EventRepeat, start: Date, until: Date?) -> GraphRecurrence? {
        let cal = Calendar.current
        let weekday = weekdays[cal.component(.weekday, from: start) - 1]
        let pattern: Pattern
        switch rule {
        case .none, .custom: return nil
        case .daily: pattern = Pattern(type: "daily", interval: 1)
        case .weekdays: pattern = Pattern(type: "weekly", interval: 1, daysOfWeek: workdays, firstDayOfWeek: "monday")
        case .weekly: pattern = Pattern(type: "weekly", interval: 1, daysOfWeek: [weekday], firstDayOfWeek: "monday")
        case .monthly: pattern = Pattern(type: "absoluteMonthly", interval: 1, dayOfMonth: cal.component(.day, from: start))
        case .yearly: pattern = Pattern(type: "absoluteYearly", interval: 1, dayOfMonth: cal.component(.day, from: start), month: cal.component(.month, from: start))
        }
        let range = until.map { Range(type: "endDate", startDate: day(start), endDate: day(max($0, start))) } ?? Range(type: "noEnd", startDate: day(start))
        return GraphRecurrence(pattern: pattern, range: range)
    }

    var rule: EventRepeat {
        guard pattern.interval == 1 else { return .custom }
        switch pattern.type {
        case "daily": return .daily
        case "weekly":
            let days = Set(pattern.daysOfWeek ?? [])
            if days == Set(Self.workdays) { return .weekdays }
            return days.count == 1 ? .weekly : .custom
        case "absoluteMonthly": return .monthly
        case "absoluteYearly": return .yearly
        default: return .custom
        }
    }

    var until: Date? {
        guard range.type == "endDate", let end = range.endDate else { return nil }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: end)
    }
}

struct GraphEvent: Decodable, Sendable {
    struct Location: Decodable, Sendable { var displayName: String? }
    struct Organizer: Decodable, Sendable { var emailAddress: EmailAddress? }
    struct ResponseStatus: Decodable, Sendable { var response: String? }
    struct Attendee: Decodable, Sendable { var emailAddress: EmailAddress?; var type: String?; var status: ResponseStatus? }
    struct OnlineMeeting: Decodable, Sendable { var joinUrl: String? }
    struct Body: Decodable, Sendable { var content: String? }

    var id: String
    var subject: String?
    var start: GraphDateTime
    var end: GraphDateTime
    var isAllDay: Bool?
    var isCancelled: Bool?
    var location: Location?
    var organizer: Organizer?
    var attendees: [Attendee]?
    var webLink: URL?
    var responseStatus: ResponseStatus?
    var bodyPreview: String?
    var type: String?
    var seriesMasterId: String?
    var showAs: String?
    var isOnlineMeeting: Bool?
    var onlineMeeting: OnlineMeeting?
    var isReminderOn: Bool?
    var reminderMinutesBeforeStart: Int?
    var body: Body?
    var recurrence: GraphRecurrence?

    static let select = "id,subject,start,end,isAllDay,isCancelled,location,organizer,attendees,webLink,responseStatus,bodyPreview,type,seriesMasterId,showAs,isOnlineMeeting,onlineMeeting,isReminderOn,reminderMinutesBeforeStart"

    var event: CalendarEvent? {
        guard let s = start.date, let e = end.date else { return nil }
        return CalendarEvent(
            id: id, source: .microsoft, title: subject ?? "(sem título)", start: s, end: e, isAllDay: isAllDay ?? false,
            location: location?.displayName, organizer: organizer?.emailAddress?.name ?? organizer?.emailAddress?.address,
            attendees: (attendees ?? []).compactMap { a in
                guard let name = a.emailAddress?.name ?? a.emailAddress?.address else { return nil }
                return CalendarEvent.Invitee(name: name, address: a.emailAddress?.address, response: a.status?.response, isOptional: a.type == "optional")
            },
            webLink: webLink, isCancelled: isCancelled ?? false, response: responseStatus?.response, bodyPreview: bodyPreview,
            showAs: showAs, joinURL: onlineMeeting?.joinUrl.flatMap(URL.init(string:)),
            seriesMasterID: type == "occurrence" || type == "exception" ? seriesMasterId : (type == "seriesMaster" ? id : nil),
            reminderMinutes: isReminderOn == true ? reminderMinutesBeforeStart ?? 15 : nil
        )
    }
}

/// Campos para criar ou editar (PATCH) um evento na Agenda Microsoft. Campo nil não vai no JSON, então não muda no servidor.
public struct EventDraft: Encodable, Sendable {
    struct Body: Encodable { var contentType = "text"; var content: String }
    struct Attendee: Encodable { var emailAddress: EmailAddress; var type = "required" }
    struct Location: Encodable { var displayName: String }

    var subject: String?
    var start: GraphDateTime?
    var end: GraphDateTime?
    var isAllDay: Bool?
    var location: Location?
    var attendees: [Attendee]?
    var body: Body?
    var showAs: String?
    var isReminderOn: Bool?
    var reminderMinutesBeforeStart: Int?
    var isOnlineMeeting: Bool?
    var onlineMeetingProvider: String?
    var recurrence: GraphRecurrence?

    private init() {}

    /// `notes`/`attendees` nil = não mexe (na edição, para não apagar o corpo HTML com o bloco do Teams).
    /// `teamsMeeting` só liga; desligar uma reunião online existente não é suportado pelo Graph.
    public init(title: String, start: Date, end: Date, isAllDay: Bool = false, location: String? = nil, attendees: [String]? = [], notes: String? = nil,
                showAs: String = "busy", reminderMinutes: Int? = 15, teamsMeeting: Bool = false, repeatRule: EventRepeat = .none, repeatUntil: Date? = nil) {
        subject = title
        self.start = .make(start)
        self.end = .make(end)
        self.isAllDay = isAllDay
        self.location = Location(displayName: location ?? "")
        self.attendees = attendees.map { $0.map { Attendee(emailAddress: Recipient(parsing: $0).emailAddress) } }
        body = notes.map { Body(content: $0) }
        self.showAs = showAs
        isReminderOn = reminderMinutes != nil
        reminderMinutesBeforeStart = reminderMinutes
        if teamsMeeting { isOnlineMeeting = true; onlineMeetingProvider = "teamsForBusiness" }
        recurrence = GraphRecurrence.make(repeatRule, start: start, until: repeatUntil)
    }

    /// Só o horário (arrastar ou esticar na grade).
    public static func move(start: Date, end: Date) -> EventDraft {
        var d = EventDraft()
        d.start = .make(start)
        d.end = .make(end)
        return d
    }
}

public extension GraphClient {
    static let calendarHeaders = ["Prefer": "outlook.timezone=\"\(TimeZone.current.identifier)\""]

    /// Eventos da Agenda Microsoft no intervalo (ocorrências de recorrentes já expandidas).
    func events(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        let iso = ISO8601DateFormatter()
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("me/calendarView"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "startDateTime", value: iso.string(from: start)),
            .init(name: "endDateTime", value: iso.string(from: end)),
            .init(name: "$top", value: "200"),
            .init(name: "$orderby", value: "start/dateTime"),
            .init(name: "$select", value: GraphEvent.select),
        ]
        var url: URL? = components.url
        var all: [CalendarEvent] = []
        while let next = url {
            let page: GraphPage<GraphEvent> = try await get(url: next, headers: Self.calendarHeaders)
            all += page.value.compactMap(\.event)
            url = page.nextLink
        }
        return all
    }

    /// Evento com corpo em texto e regra de repetição, para o editor. Para editar a série, passe o id da série.
    func eventDetails(id: String) async throws -> EventDetails {
        let headers = ["Prefer": "outlook.timezone=\"\(TimeZone.current.identifier)\", outlook.body-content-type=\"text\""]
        let g: GraphEvent = try await get("me/events/\(id)", query: [.init(name: "$select", value: GraphEvent.select + ",body,recurrence")], headers: headers)
        guard let event = g.event else { throw URLError(.cannotParseResponse) }
        return EventDetails(event: event, notes: (g.body?.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                            repeatRule: g.recurrence?.rule ?? .none, repeatUntil: g.recurrence?.until, isOnlineMeeting: g.isOnlineMeeting ?? false)
    }

    func createEvent(_ draft: EventDraft) async throws {
        try await post("me/events", json: JSONEncoder().encode(draft))
    }

    func updateEvent(id: String, _ draft: EventDraft) async throws {
        try await patch("me/events/\(id)", json: JSONEncoder().encode(draft))
    }

    /// Apagar uma reunião que você organiza manda o cancelamento aos convidados (comportamento do Graph).
    func deleteEvent(id: String) async throws {
        try await delete("me/events/\(id)")
    }

    /// O evento ligado a uma mensagem de convite (eventMessage), se existir.
    func event(forMeetingMessage id: String) async throws -> CalendarEvent? {
        struct Wrapper: Decodable { var event: GraphEvent? }
        let w: Wrapper = try await get("me/messages/\(id)", query: [
            .init(name: "$select", value: "id"),
            .init(name: "$expand", value: "microsoft.graph.eventMessage/event"),
        ], headers: Self.calendarHeaders)
        return w.event?.event
    }

    /// accept, decline ou tentativelyAccept.
    func respond(eventID: String, _ action: String, comment: String? = nil) async throws {
        let body = ["sendResponse": true, "comment": comment ?? ""] as [String: Any]
        try await post("me/events/\(eventID)/\(action)", json: JSONSerialization.data(withJSONObject: body))
    }
}

// MARK: Datas

public extension Calendar {
    /// Segunda a domingo da semana que contém `date`.
    func weekInterval(containing date: Date) -> DateInterval {
        var cal = self
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
        return DateInterval(start: start, end: cal.date(byAdding: .day, value: 7, to: start)!)
    }

    /// Grade do mês: 6 semanas (42 dias) a partir da segunda que abre a semana do dia 1.
    func monthGridInterval(containing date: Date) -> DateInterval {
        let first = dateInterval(of: .month, for: date)!.start
        let start = weekInterval(containing: first).start
        return DateInterval(start: start, end: self.date(byAdding: .day, value: 42, to: start)!)
    }
}

/// Lugar de um evento na coluna do dia: `column` de `columns` lado a lado.
public struct EventSlot: Equatable, Sendable {
    public var column: Int
    public var columns: Int

    public init(column: Int, columns: Int) { self.column = column; self.columns = columns }
}

public extension CalendarEvent {
    /// Distribui eventos que se sobrepõem em colunas lado a lado (como o Calendário da Apple).
    /// Grupo = eventos ligados por sobreposição; todos do grupo dividem a largura pelo mesmo número de colunas.
    static func slots(for events: [CalendarEvent]) -> [String: EventSlot] {
        var result: [String: EventSlot] = [:]
        var group: [(id: String, column: Int)] = []
        var columnEnds: [Date] = []
        var groupEnd = Date.distantPast
        func close() {
            for item in group { result[item.id] = EventSlot(column: item.column, columns: columnEnds.count) }
            group = []; columnEnds = []
        }
        for e in events.sorted(by: { ($0.start, $1.end) < ($1.start, $0.end) }) {
            if e.start >= groupEnd { close() }
            let end = max(e.end, e.start.addingTimeInterval(15 * 60)) // evento curto ocupa ao menos 15 min na tela
            if let free = columnEnds.firstIndex(where: { $0 <= e.start }) {
                columnEnds[free] = end
                group.append((e.id, free))
            } else {
                columnEnds.append(end)
                group.append((e.id, columnEnds.count - 1))
            }
            groupEnd = max(groupEnd, end)
        }
        close()
        return result
    }
}
