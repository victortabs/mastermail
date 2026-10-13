import Foundation

/// Evento de agenda, da Agenda Microsoft (editável) ou da Agenda do Mac (só leitura). Ver CONTEXT.md.
public struct CalendarEvent: Identifiable, Sendable, Hashable {
    public enum Source: Sendable, Hashable { case microsoft, mac(calendar: String) }

    public var id: String
    public var source: Source
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var location: String?
    public var organizer: String?
    public var attendees: [String]
    public var webLink: URL?
    public var isCancelled: Bool
    /// Resposta do usuário na Agenda Microsoft: accepted, tentativelyAccepted, declined, notResponded, organizer, none.
    public var response: String?
    public var bodyPreview: String?

    public var isEditable: Bool { if case .microsoft = source { return true } else { return false } }

    public init(id: String, source: Source, title: String, start: Date, end: Date, isAllDay: Bool, location: String? = nil, organizer: String? = nil, attendees: [String] = [], webLink: URL? = nil, isCancelled: Bool = false, response: String? = nil, bodyPreview: String? = nil) {
        self.id = id; self.source = source; self.title = title; self.start = start; self.end = end; self.isAllDay = isAllDay
        self.location = location; self.organizer = organizer; self.attendees = attendees; self.webLink = webLink
        self.isCancelled = isCancelled; self.response = response; self.bodyPreview = bodyPreview
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

struct GraphEvent: Decodable, Sendable {
    struct Location: Decodable, Sendable { var displayName: String? }
    struct Organizer: Decodable, Sendable { var emailAddress: EmailAddress? }
    struct Attendee: Decodable, Sendable { var emailAddress: EmailAddress? }
    struct ResponseStatus: Decodable, Sendable { var response: String? }

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

    var event: CalendarEvent? {
        guard let s = start.date, let e = end.date else { return nil }
        return CalendarEvent(
            id: id, source: .microsoft, title: subject ?? "(sem título)", start: s, end: e, isAllDay: isAllDay ?? false,
            location: location?.displayName, organizer: organizer?.emailAddress?.name ?? organizer?.emailAddress?.address,
            attendees: (attendees ?? []).compactMap { $0.emailAddress?.name ?? $0.emailAddress?.address },
            webLink: webLink, isCancelled: isCancelled ?? false, response: responseStatus?.response, bodyPreview: bodyPreview
        )
    }
}

/// Campos para criar ou editar um evento na Agenda Microsoft.
public struct EventDraft: Encodable, Sendable {
    struct Body: Encodable { var contentType = "text"; var content: String }
    struct Attendee: Encodable { var emailAddress: EmailAddress; var type = "required" }
    struct Location: Encodable { var displayName: String }

    var subject: String
    var start: GraphDateTime
    var end: GraphDateTime
    var isAllDay: Bool
    var location: Location?
    var attendees: [Attendee]
    var body: Body?

    public init(title: String, start: Date, end: Date, isAllDay: Bool = false, location: String? = nil, attendees: [String] = [], notes: String? = nil) {
        subject = title
        self.start = .make(start)
        self.end = .make(end)
        self.isAllDay = isAllDay
        self.location = location.map { Location(displayName: $0) }
        self.attendees = attendees.map { Attendee(emailAddress: Recipient(parsing: $0).emailAddress) }
        body = notes.map { Body(content: $0) }
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
            .init(name: "$select", value: "id,subject,start,end,isAllDay,isCancelled,location,organizer,attendees,webLink,responseStatus,bodyPreview"),
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

    func createEvent(_ draft: EventDraft) async throws {
        try await post("me/events", json: JSONEncoder().encode(draft))
    }

    func updateEvent(id: String, _ draft: EventDraft) async throws {
        try await patch("me/events/\(id)", json: JSONEncoder().encode(draft))
    }

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
}
