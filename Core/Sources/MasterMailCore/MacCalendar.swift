import EventKit
import Foundation

/// Agenda do Mac (ver CONTEXT.md): calendários e lembretes que o macOS já conhece, via EventKit.
/// Calendário só leitura no MasterMail; Lembretes leitura e escrita.
@MainActor
public final class MacCalendar {
    private let store = EKEventStore()

    public init() {}

    /// Pede acesso total (não existe só-leitura no EventKit). false = negado ou sem chave no Info.plist.
    public func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    public func requestRemindersAccess() async -> Bool {
        (try? await store.requestFullAccessToReminders()) ?? false
    }

    /// Calendários do Mac que o MasterMail mostra (mesmo filtro de `events`), com a cor de cada um.
    public func calendars() -> [(title: String, colorHex: String?)] {
        store.calendars(for: .event).filter { $0.source.sourceType != .exchange }
            .map { ($0.title, $0.cgColor.flatMap(Self.hex)) }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }

    /// Só calendários que NÃO são Exchange: a conta Microsoft já vem pelo Graph, senão cada evento aparece duas vezes.
    public func events(from start: Date, to end: Date) -> [CalendarEvent] {
        let calendars = store.calendars(for: .event).filter { $0.source.sourceType != .exchange }
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate).map { e in
            CalendarEvent(
                id: "mac:" + (e.eventIdentifier ?? UUID().uuidString) + ":" + String(Int(e.startDate.timeIntervalSince1970)),
                source: .mac(calendar: e.calendar.title),
                title: e.title ?? "(sem título)", start: e.startDate, end: e.endDate, isAllDay: e.isAllDay,
                location: e.location, organizer: e.organizer?.name,
                attendees: (e.attendees ?? []).compactMap { $0.name.map { CalendarEvent.Invitee(name: $0) } }, isCancelled: e.status == .canceled,
                colorHex: e.calendar.cgColor.flatMap(Self.hex),
                showAs: e.availability == .free ? "free" : nil,
                joinURL: CalendarEvent.meetingLink(in: [e.url?.absoluteString, e.location, e.notes]),
                seriesMasterID: e.hasRecurrenceRules ? e.calendarItemIdentifier : nil
            )
        }
    }

    private static func hex(_ color: CGColor) -> String? {
        guard let rgb = color.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components,
              rgb.count >= 3 else { return nil }
        return String(format: "#%02X%02X%02X", Int(rgb[0] * 255), Int(rgb[1] * 255), Int(rgb[2] * 255))
    }

    /// Cria um Lembrete na lista padrão do Lembretes.app (tarefa a partir de uma mensagem).
    public func createReminder(title: String, notes: String?, due: Date?) throws {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = store.defaultCalendarForNewReminders()
        if let due {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            reminder.addAlarm(EKAlarm(absoluteDate: due))
        }
        try store.save(reminder, commit: true)
    }
}
