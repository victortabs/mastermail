import MasterMailCore
import SwiftUI

/// Agenda Microsoft (editável) + Agenda do Mac (só leitura) no mesmo grid.
@MainActor
@Observable
final class CalendarModel {
    enum Mode { case day, week }

    private let graph: GraphClient
    private let mac = MacCalendar()
    var mode: Mode = .week
    var anchor = Date()
    private(set) var events: [CalendarEvent] = []
    private(set) var upcomingToday: [CalendarEvent] = []
    private(set) var isLoading = false
    private(set) var macAccess = false
    var error: String?
    private var loadGeneration = UUID()

    init(graph: GraphClient) { self.graph = graph }

    var interval: DateInterval {
        let cal = Calendar.current
        switch mode {
        case .week: return cal.weekInterval(containing: anchor)
        case .day:
            let start = cal.startOfDay(for: anchor)
            return DateInterval(start: start, end: cal.date(byAdding: .day, value: 1, to: start)!)
        }
    }

    var days: [Date] {
        let cal = Calendar.current
        let count = mode == .week ? 7 : 1
        return (0 ..< count).map { cal.date(byAdding: .day, value: $0, to: interval.start)! }
    }

    func load(requestMacAccess: Bool = true) async {
        let generation = UUID()
        loadGeneration = generation
        let range = interval
        isLoading = true
        defer { if loadGeneration == generation { isLoading = false } }
        if requestMacAccess { macAccess = await mac.requestAccess() }
        else { macAccess = mac.hasCalendarAccess }
        guard loadGeneration == generation else { return }
        do {
            async let ms = graph.events(from: range.start, to: range.end)
            let macEvents = macAccess ? mac.events(from: range.start, to: range.end) : []
            // Segunda barreira contra duplicata: mesmo título e mesmo início contam uma vez só (fica o da Microsoft).
            var seen = Set<String>()
            let combined = try await ms + macEvents
            guard loadGeneration == generation, !Task.isCancelled else { return }
            error = nil
            events = combined.filter { seen.insert("\($0.title)|\(Int($0.start.timeIntervalSince1970))").inserted }.sorted { $0.start < $1.start }
            await loadToday()
        } catch {
            if loadGeneration == generation, !Task.isCancelled { self.error = error.localizedDescription }
        }
    }

    func loadToday() async {
        macAccess = mac.hasCalendarAccess
        let cal = Calendar.current
        let start = Date()
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: start))!
        let ms = (try? await graph.events(from: cal.startOfDay(for: start), to: end)) ?? []
        let macEvents = macAccess ? mac.events(from: cal.startOfDay(for: start), to: end) : []
        upcomingToday = (ms + macEvents).filter { $0.end > start && !$0.isCancelled }.sorted { $0.start < $1.start }
    }

    func shift(_ delta: Int) async {
        let unit: Calendar.Component = mode == .week ? .weekOfYear : .day
        anchor = Calendar.current.date(byAdding: unit, value: delta, to: anchor)!
        await load()
    }

    func today() async { anchor = Date(); await load() }

    func setMode(_ m: Mode) async { mode = m; await load() }

    func respond(_ event: CalendarEvent, _ action: String) async {
        do { try await graph.respond(eventID: event.id, action); await load() } catch { self.error = error.localizedDescription }
    }

    func delete(_ event: CalendarEvent) async {
        do { try await graph.deleteEvent(id: event.id); await load() } catch { self.error = error.localizedDescription }
    }

    func create(_ draft: EventDraft) async -> Bool {
        do { try await graph.createEvent(draft); await load(); return true }
        catch { self.error = error.localizedDescription; return false }
    }

    func events(on day: Date, allDay: Bool) -> [CalendarEvent] {
        let cal = Calendar.current
        return events.filter { e in
            e.isAllDay == allDay && !e.isCancelled &&
                (cal.isDate(e.start, inSameDayAs: day) || (e.start < cal.startOfDay(for: day) && e.end > cal.startOfDay(for: day)))
        }
    }
}

struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: CalendarEvent?
    @State private var creating = false

    private var cal: CalendarModel? { model.calendar }

    var body: some View {
        Group {
            if let cal {
                CalendarGrid(cal: cal, selected: $selected)
                    .navigationTitle(cal.interval.start.formatted(.dateTime.month(.wide).year()))
                    .navigationSubtitle(cal.mode == .week ? "Semana de \(cal.interval.start.formatted(.dateTime.day().month()))" : cal.anchor.formatted(.dateTime.weekday(.wide).day().month()))
                    .toolbar {
                        ToolbarItem(placement: .navigation) { ViewPicker() }
                        ToolbarItemGroup {
                            Button("Hoje") { Task { await cal.today() } }.keyboardShortcut("t", modifiers: [])
                            Button { Task { await cal.shift(-1) } } label: { Image(systemName: "chevron.left") }.keyboardShortcut(.leftArrow, modifiers: [])
                            Button { Task { await cal.shift(1) } } label: { Image(systemName: "chevron.right") }.keyboardShortcut(.rightArrow, modifiers: [])
                            Picker("Modo", selection: Binding(get: { cal.mode }, set: { m in Task { await cal.setMode(m) } })) {
                                Text("Dia").tag(CalendarModel.Mode.day)
                                Text("Semana").tag(CalendarModel.Mode.week)
                            }.pickerStyle(.segmented)
                            Button { creating = true } label: { Label("Novo evento", systemImage: "plus") }.keyboardShortcut("n", modifiers: [])
                        }
                    }
                    .sheet(isPresented: $creating) { EventEditor(cal: cal, defaultStart: cal.anchor) }
                    .popover(item: $selected) { e in EventDetail(event: e, cal: cal) { selected = nil } }
                    .alert("Erro", isPresented: Binding(get: { cal.error != nil }, set: { if !$0 { cal.error = nil } })) {
                        Button("OK") { cal.error = nil }
                    } message: { Text(cal.error ?? "") }
                    .task { await cal.load() }
            } else {
                ContentUnavailableView("Calendário", systemImage: "calendar", description: Text("Entre com a conta para ver a agenda."))
            }
        }
    }
}

struct CalendarGrid: View {
    @Bindable var cal: CalendarModel
    @Binding var selected: CalendarEvent?
    private let hourHeight: CGFloat = 48
    private let gutter: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho dos dias + eventos de dia inteiro
            HStack(spacing: 0) {
                Color.clear.frame(width: gutter)
                ForEach(cal.days, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)).uppercased()).font(.caption2).foregroundStyle(.secondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.title3.weight(Calendar.current.isDateInToday(day) ? .bold : .regular))
                            .foregroundStyle(Calendar.current.isDateInToday(day) ? Color.accentColor : .primary)
                        ForEach(cal.events(on: day, allDay: true)) { e in
                            EventChip(event: e, compact: true).onTapGesture { selected = e }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach(0 ..< 24, id: \.self) { h in
                                Text(String(format: "%02d:00", h)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                                    .frame(width: gutter, height: hourHeight, alignment: .topTrailing).padding(.trailing, 4).id("h\(h)")
                            }
                        }
                        ForEach(cal.days, id: \.self) { day in
                            DayColumn(day: day, events: cal.events(on: day, allDay: false), hourHeight: hourHeight, selected: $selected)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .onAppear { proxy.scrollTo("h7", anchor: .top) }
            }
        }
        .overlay(alignment: .topTrailing) { if cal.isLoading { ProgressView().controlSize(.small).padding() } }
    }
}

struct DayColumn: View {
    let day: Date
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    @Binding var selected: CalendarEvent?

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0 ..< 24, id: \.self) { _ in
                    Rectangle().fill(.clear).frame(height: hourHeight).overlay(alignment: .top) { Divider() }
                }
            }
            .background(Calendar.current.isDateInToday(day) ? Color.accentColor.opacity(0.04) : .clear)
            .overlay(alignment: .leading) { Divider() }
            ForEach(Array(events.enumerated()), id: \.element.id) { index, e in
                let dayStart = Calendar.current.startOfDay(for: day)
                let top = max(0, e.start.timeIntervalSince(dayStart)) / 3600 * hourHeight
                let bottom = min(24 * 3600, e.end.timeIntervalSince(dayStart)) / 3600 * hourHeight
                EventChip(event: e, compact: false)
                    .frame(height: max(18, bottom - top))
                    .padding(.leading, CGFloat(index % 3) * 6 + 2)
                    .padding(.trailing, 2)
                    .offset(y: top)
                    .onTapGesture { selected = e }
            }
            if Calendar.current.isDateInToday(day) {
                let now = Date().timeIntervalSince(Calendar.current.startOfDay(for: day)) / 3600 * hourHeight
                Rectangle().fill(.red).frame(height: 1).offset(y: now)
            }
        }
    }
}

struct EventChip: View {
    let event: CalendarEvent
    let compact: Bool

    private var color: Color {
        if event.isCancelled { return .gray }
        switch event.source {
        case .microsoft: return event.response == "declined" ? .gray : .blue
        case .mac: return .teal
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                if !event.isEditable { Image(systemName: "lock.fill").font(.system(size: 8)) }
                Text(event.title).font(.caption.weight(.medium)).lineLimit(compact ? 1 : 2)
            }
            if !compact, let location = event.location, !location.isEmpty {
                Text(location).font(.caption2).lineLimit(1).opacity(0.8)
            }
        }
        .padding(.horizontal, 4).padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(event.response == "tentativelyAccepted" ? 0.12 : 0.22), in: RoundedRectangle(cornerRadius: 4))
        .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 3) }
        .foregroundStyle(.primary)
        .strikethrough(event.isCancelled)
    }
}

struct EventDetail: View {
    let event: CalendarEvent
    let cal: CalendarModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title).font(.headline)
            Text(event.isAllDay ? event.start.formatted(.dateTime.weekday(.wide).day().month()) + " · dia todo"
                 : "\(event.start.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())) – \(event.end.formatted(date: .omitted, time: .shortened))")
                .foregroundStyle(.secondary)
            if let location = event.location, !location.isEmpty { Label(location, systemImage: "mappin") }
            if let organizer = event.organizer { Label(organizer, systemImage: "person") }
            if !event.attendees.isEmpty { Label(event.attendees.joined(separator: ", "), systemImage: "person.2").lineLimit(3) }
            if case let .mac(calendar) = event.source { Label("Agenda do Mac · \(calendar) · só leitura", systemImage: "lock") .foregroundStyle(.secondary) }
            if let preview = event.bodyPreview, !preview.isEmpty { Text(preview).font(.callout).foregroundStyle(.secondary).lineLimit(6) }
            if event.isEditable {
                HStack {
                    if event.response != "organizer" {
                        Button("Aceitar") { Task { await cal.respond(event, "accept"); onClose() } }
                        Button("Talvez") { Task { await cal.respond(event, "tentativelyAccept"); onClose() } }
                        Button("Recusar") { Task { await cal.respond(event, "decline"); onClose() } }
                    }
                    Spacer()
                    Button("Apagar", role: .destructive) { Task { await cal.delete(event); onClose() } }
                }
                .controlSize(.small)
            }
            if let link = event.webLink { Link("Abrir no Outlook", destination: link).font(.caption) }
        }
        .padding()
        .frame(width: 340)
    }
}

struct EventEditor: View {
    let cal: CalendarModel
    let defaultStart: Date
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var start: Date
    @State private var end: Date
    @State private var allDay = false
    @State private var location = ""
    @State private var attendees = ""
    @State private var notes = ""
    @State private var isCreating = false

    init(cal: CalendarModel, defaultStart: Date, prefillTitle: String = "", prefillAttendees: String = "", prefillNotes: String = "") {
        self.cal = cal
        self.defaultStart = defaultStart
        let c = Calendar.current
        let next = c.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? Date()
        let s = c.isDateInToday(defaultStart) ? next : c.date(bySettingHour: 9, minute: 0, second: 0, of: defaultStart)!
        _start = State(initialValue: s)
        _end = State(initialValue: c.date(byAdding: .hour, value: 1, to: s)!)
        _title = State(initialValue: prefillTitle)
        _attendees = State(initialValue: prefillAttendees)
        _notes = State(initialValue: prefillNotes)
    }

    var body: some View {
        Form {
            TextField("Título", text: $title)
            Toggle("Dia todo", isOn: $allDay)
            DatePicker("Início", selection: $start, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
            DatePicker("Fim", selection: $end, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
            TextField("Local", text: $location)
            TextField("Convidados (e-mails separados por vírgula)", text: $attendees)
            TextField("Notas", text: $notes, axis: .vertical).lineLimit(3 ... 6)
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .disabled(isCreating)
        .interactiveDismissDisabled(isCreating)
        .navigationTitle("Novo evento na Agenda Microsoft")
        .alert("Não foi possível criar o evento", isPresented: Binding(get: { cal.error != nil }, set: { if !$0 { cal.error = nil } })) {
            Button("OK") { cal.error = nil }
        } message: { Text(cal.error ?? "") }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Criar") {
                    let draft = EventDraft(title: title, start: start, end: max(end, start), isAllDay: allDay,
                                           location: location.isEmpty ? nil : location,
                                           attendees: attendees.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
                                           notes: notes.isEmpty ? nil : notes)
                    Task {
                        isCreating = true
                        defer { isCreating = false }
                        if await cal.create(draft) { dismiss() }
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(isCreating || title.trimmingCharacters(in: .whitespaces).isEmpty || end <= start)
            }
        }
    }
}
