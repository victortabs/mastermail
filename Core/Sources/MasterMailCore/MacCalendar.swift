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

    public func events(from start: Date, to end: Date) -> [CalendarEvent] {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { e in
            CalendarEvent(
                id: "mac:" + (e.eventIdentifier ?? UUID().uuidString) + ":" + String(Int(e.startDate.timeIntervalSince1970)),
                source: .mac(calendar: e.calendar.title),
                title: e.title ?? "(sem título)", start: e.startDate, end: e.endDate, isAllDay: e.isAllDay,
                location: e.location, organizer: e.organizer?.name,
                attendees: (e.attendees ?? []).compactMap(\.name), isCancelled: e.status == .canceled
            )
        }
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
