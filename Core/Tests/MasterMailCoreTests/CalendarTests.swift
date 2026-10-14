import Foundation
@testable import MasterMailCore
import Testing

struct CalendarTests {
    @Test func graphEventDecodesInRequestedTimeZone() throws {
        let json = """
        {"id":"e1","subject":"Reunião de obra","start":{"dateTime":"2026-10-14T09:00:00.0000000","timeZone":"America/Sao_Paulo"},
         "end":{"dateTime":"2026-10-14T10:30:00.0000000","timeZone":"America/Sao_Paulo"},"isAllDay":false,
         "location":{"displayName":"Oscar Freire"},"organizer":{"emailAddress":{"name":"Marina","address":"m@bdil.com.br"}},
         "attendees":[{"emailAddress":{"name":"Victor","address":"v@vhicom.com.br"}}],"responseStatus":{"response":"accepted"}}
        """
        let event = try GraphClient.decoder.decode(GraphEvent.self, from: Data(json.utf8)).event
        #expect(event?.title == "Reunião de obra")
        #expect(event?.location == "Oscar Freire")
        #expect(event?.attendees.map(\.name) == ["Victor"])
        #expect(event?.response == "accepted")
        let sp = TimeZone(identifier: "America/Sao_Paulo")!
        let comps = Calendar.current.dateComponents(in: sp, from: event!.start)
        #expect(comps.hour == 9 && comps.minute == 0)
        #expect(event!.end.timeIntervalSince(event!.start) == 90 * 60)
    }

    @Test func weekStartsOnMonday() {
        let cal = Calendar(identifier: .gregorian)
        let wed = cal.date(from: DateComponents(year: 2026, month: 10, day: 14))! // quarta
        let week = cal.weekInterval(containing: wed)
        #expect(cal.component(.weekday, from: week.start) == 2)
        #expect(cal.component(.day, from: week.start) == 12)
        #expect(cal.dateComponents([.day], from: week.start, to: week.end).day == 7)
    }

    @Test func eventDraftEncodesAttendeesAndTimeZone() throws {
        let draft = EventDraft(title: "Visita", start: Date(timeIntervalSince1970: 1_792_000_000), end: Date(timeIntervalSince1970: 1_792_003_600), attendees: ["Marina <m@bdil.com.br>"])
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(draft)) as! [String: Any]
        #expect(json["subject"] as? String == "Visita")
        #expect((json["start"] as! [String: Any])["timeZone"] as? String == TimeZone.current.identifier)
        #expect(((json["attendees"] as! [[String: Any]])[0]["emailAddress"] as! [String: Any])["address"] as? String == "m@bdil.com.br")
    }

    @Test func overlappingEventsShareWidth() {
        let t0 = Date(timeIntervalSince1970: 1_792_000_000)
        func e(_ id: String, _ from: Double, _ to: Double) -> CalendarEvent {
            CalendarEvent(id: id, source: .microsoft, title: id, start: t0.addingTimeInterval(from * 3600), end: t0.addingTimeInterval(to * 3600), isAllDay: false)
        }
        // a 9–11, b 10–12 e c 11–12 se ligam; c reaproveita a coluna de a. d 13–14 fica sozinho.
        let slots = CalendarEvent.slots(for: [e("c", 2, 3), e("a", 0, 2), e("d", 4, 5), e("b", 1, 3)])
        #expect(slots["a"] == EventSlot(column: 0, columns: 2))
        #expect(slots["b"] == EventSlot(column: 1, columns: 2))
        #expect(slots["c"] == EventSlot(column: 0, columns: 2))
        #expect(slots["d"] == EventSlot(column: 0, columns: 1))
    }

    @Test func monthGridHasSixWeeksFromMonday() {
        let cal = Calendar(identifier: .gregorian)
        let grid = cal.monthGridInterval(containing: cal.date(from: DateComponents(year: 2026, month: 10, day: 14))!)
        #expect(cal.component(.weekday, from: grid.start) == 2)
        #expect(cal.dateComponents([.month, .day], from: grid.start) == DateComponents(month: 9, day: 28))
        #expect(cal.dateComponents([.day], from: grid.start, to: grid.end).day == 42)
    }

    @Test func graphEventReadsTeamsSeriesReminderAndAttendeeStatus() throws {
        let json = """
        {"id":"o1","subject":"Semanal","start":{"dateTime":"2026-10-14T09:00:00","timeZone":"UTC"},"end":{"dateTime":"2026-10-14T10:00:00","timeZone":"UTC"},
         "type":"occurrence","seriesMasterId":"m1","showAs":"tentative","isOnlineMeeting":true,
         "onlineMeeting":{"joinUrl":"https://teams.microsoft.com/l/meetup-join/abc"},"isReminderOn":true,"reminderMinutesBeforeStart":10,
         "attendees":[{"emailAddress":{"name":"Ana","address":"ana@x.test"},"type":"optional","status":{"response":"declined"}}],
         "responseStatus":{"response":"organizer"}}
        """
        let e = try #require(try GraphClient.decoder.decode(GraphEvent.self, from: Data(json.utf8)).event)
        #expect(e.seriesMasterID == "m1" && e.isRecurring)
        #expect(e.showAs == "tentative")
        #expect(e.joinURL?.host() == "teams.microsoft.com")
        #expect(e.reminderMinutes == 10)
        #expect(e.attendees == [CalendarEvent.Invitee(name: "Ana", address: "ana@x.test", response: "declined", isOptional: true)])
        #expect(e.canEdit)
    }

    @Test func meetingLinkFoundInLocationOrBody() {
        #expect(CalendarEvent.meetingLink(in: [nil, "Entre: https://us02web.zoom.us/j/123?pwd=x obrigado"])?.absoluteString == "https://us02web.zoom.us/j/123?pwd=x")
        #expect(CalendarEvent.meetingLink(in: ["Sala 3", "https://example.com/agenda"]) == nil)
    }

    @Test func repeatRulesRoundTrip() throws {
        let cal = Calendar.current
        let wed = cal.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 9))!
        for rule in [EventRepeat.daily, .weekdays, .weekly, .monthly, .yearly] {
            #expect(GraphRecurrence.make(rule, start: wed, until: nil)?.rule == rule)
        }
        let weekly = try #require(GraphRecurrence.make(.weekly, start: wed, until: cal.date(byAdding: .month, value: 1, to: wed)))
        #expect(weekly.pattern.daysOfWeek == ["wednesday"])
        #expect(weekly.range.type == "endDate" && weekly.range.endDate == "2026-11-14")
        #expect(GraphRecurrence.make(.none, start: wed, until: nil) == nil)
    }

    @Test func editDraftLeavesUntouchedFieldsOut() throws {
        let t = Date(timeIntervalSince1970: 1_792_000_000)
        let move = try JSONSerialization.jsonObject(with: JSONEncoder().encode(EventDraft.move(start: t, end: t.addingTimeInterval(1800)))) as! [String: Any]
        #expect(Set(move.keys) == ["start", "end"])
        let edit = try JSONSerialization.jsonObject(with: JSONEncoder().encode(EventDraft(title: "X", start: t, end: t, attendees: nil, notes: nil, reminderMinutes: nil, teamsMeeting: true))) as! [String: Any]
        #expect(edit["body"] == nil && edit["attendees"] == nil && edit["recurrence"] == nil)
        #expect(edit["isReminderOn"] as? Bool == false)
        #expect(edit["onlineMeetingProvider"] as? String == "teamsForBusiness")
    }
}
