import Foundation
@testable import MasterMailCore
import Testing

struct AvailabilityTests {
    let cal = Calendar.current

    @Test func freeSlotsSkipBusyAndTooSoon() {
        let day = cal.date(from: DateComponents(year: 2026, month: 10, day: 15))!
        func at(_ h: Double) -> Date { day.addingTimeInterval(h * 3600) }
        let busy = [DateInterval(start: at(10), end: at(11.5)), DateInterval(start: at(14), end: at(14.25))]
        let slots = Availability.freeSlots(days: [day], busy: busy, workStart: 8, workEnd: 16, duration: 3600, step: 3600, now: at(7.5))
        // 8:00 é cedo demais (precisa de 1 h de folga), 10 e 11 batem na reunião, 14 bate no compromisso das 14h;
        // 9 e 13 terminam exatamente quando o ocupado começa, então valem.
        #expect(slots == [at(9), at(12), at(13), at(15)])
    }

    @Test func weekdaysOnlySkipsWeekend() {
        let fri = cal.date(from: DateComponents(year: 2026, month: 10, day: 16))!
        let days = Availability.days(from: fri, count: 3, weekdaysOnly: true)
        #expect(days.map { cal.component(.day, from: $0) } == [16, 19, 20])
    }

    @Test func replySubjectMatchesOfferReference() throws {
        let start = cal.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 10))!
        let offer = AvailabilityOffer(recipient: "Ana Lima <ana@x.test>", title: "Visita & obra", durationMinutes: 30, teams: true, slots: [start, start.addingTimeInterval(3600)])
        let m = try #require(AvailabilityOffer.match(subject: "RE: Confirmado: Visita — qui 15/10 11:00 \(offer.reference(1))"))
        #expect(m.id == offer.id && m.index == 1)
        #expect(AvailabilityOffer.match(subject: "Re: Horários para Visita") == nil)

        let html = offer.emailHTML(replyTo: "eu@x.test")
        #expect(html.contains("Olá, Ana!"))
        #expect(html.contains("Visita &amp; obra"))
        #expect(html.contains("mailto:eu@x.test?subject="))
        #expect(html.contains("%5BMM-\(offer.id)-2%5D"))
        #expect(html.contains(">11:00</a>"))
    }

    @Test func teamsLinkOpensInApp() {
        let work = URL(string: "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc%40thread.v2/0?context=%7b%7d")!
        #expect(CalendarEvent.teamsAppURL(for: work)?.absoluteString == "msteams:/l/meetup-join/19%3ameeting_abc%40thread.v2/0?context=%7b%7d")
        #expect(CalendarEvent.teamsAppURL(for: URL(string: "https://teams.live.com/meet/123")!) == nil)
        #expect(CalendarEvent.teamsAppURL(for: URL(string: "https://zoom.us/j/1")!) == nil)
    }

    @Test func storeRoundTrips() throws {
        let store = AvailabilityStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("a.json"))
        var offer = AvailabilityOffer(recipient: "a@x.test", title: "R", durationMinutes: 30, teams: false, slots: [Date(timeIntervalSince1970: 1_792_000_000)])
        offer.status = .confirmed
        offer.chosen = 0
        try store.save([offer])
        #expect(store.load() == [offer])
    }
}
