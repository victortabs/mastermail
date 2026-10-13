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
        #expect(event?.attendees == ["Victor"])
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
}
