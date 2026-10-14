import MasterMailCore
import SwiftUI
import UserNotifications

/// Agenda Microsoft (editável) + Agenda do Mac (só leitura) no mesmo grid.
@MainActor
@Observable
final class CalendarModel {
    enum Mode { case day, week, month }

    struct EditRequest: Identifiable {
        let event: CalendarEvent
        let series: Bool
        var id: String { event.id + (series ? "#serie" : "") }
    }

    nonisolated static let microsoftName = "Agenda Microsoft"

    private let graph: GraphClient
    private let mac = MacCalendar()
    var mode: Mode = .week
    var anchor = Date()
    private(set) var events: [CalendarEvent] = []
    private(set) var upcomingToday: [CalendarEvent] = []
    private(set) var isLoading = false
    private(set) var macAccess = false
    /// Calendários da lateral: Agenda Microsoft primeiro, depois os do Mac.
    private(set) var calendars: [(name: String, colorHex: String?)] = [(CalendarModel.microsoftName, nil)]
    var hiddenCalendars: Set<String> = []
    /// Editor aberto a partir do popover do evento (só este evento ou a série toda).
    var editRequest: EditRequest?
    var error: String?
    private var loadGeneration = UUID()
    /// Disponibilidades enviadas por e-mail (mais nova primeiro).
    private(set) var offers: [AvailabilityOffer]
    private let offerStore: AvailabilityStore

    init(graph: GraphClient, offerStore: AvailabilityStore = .default()) {
        self.graph = graph
        self.offerStore = offerStore
        offers = offerStore.load()
    }

    var interval: DateInterval {
        let cal = Calendar.current
        switch mode {
        case .month: return cal.monthGridInterval(containing: anchor)
        case .week: return cal.weekInterval(containing: anchor)
        case .day:
            let start = cal.startOfDay(for: anchor)
            return DateInterval(start: start, end: cal.date(byAdding: .day, value: 1, to: start)!)
        }
    }

    var days: [Date] {
        let cal = Calendar.current
        let count = cal.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1
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
        if macAccess { calendars = [(Self.microsoftName, nil)] + mac.calendars().map { (name: $0.title, colorHex: $0.colorHex) } }
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
        await EventReminders.schedule(upcomingToday)
    }

    func shift(_ delta: Int) async {
        let unit: Calendar.Component = switch mode {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        }
        anchor = Calendar.current.date(byAdding: unit, value: delta, to: anchor)!
        await load()
    }

    func today() async { anchor = Date(); await load() }

    func go(to date: Date, mode m: Mode? = nil) async {
        let before = interval
        anchor = date
        if let m { mode = m }
        if interval != before { await load() }
    }

    func setMode(_ m: Mode) async { mode = m; await load() }

    func respond(_ event: CalendarEvent, _ action: String) async {
        do { try await graph.respond(eventID: event.id, action); await load() } catch { self.error = error.localizedDescription }
    }

    func delete(_ event: CalendarEvent, series: Bool = false) async {
        let id = series ? event.seriesMasterID ?? event.id : event.id
        do { try await graph.deleteEvent(id: id); await load() } catch { self.error = error.localizedDescription }
    }

    func create(_ draft: EventDraft) async -> Bool {
        do { try await graph.createEvent(draft); await load(); return true }
        catch { self.error = error.localizedDescription; return false }
    }

    func update(id: String, _ draft: EventDraft) async -> Bool {
        do { try await graph.updateEvent(id: id, draft); await load(); return true }
        catch { self.error = error.localizedDescription; return false }
    }

    func details(_ event: CalendarEvent, series: Bool) async -> EventDetails? {
        do { return try await graph.eventDetails(id: series ? event.seriesMasterID ?? event.id : event.id) }
        catch { self.error = error.localizedDescription; return nil }
    }

    /// Arrastar/esticar na grade: muda na tela na hora e grava no servidor; se falhar, volta ao que o servidor tem.
    func move(_ event: CalendarEvent, start: Date, end: Date) {
        guard let i = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[i].start = start
        events[i].end = end
        Task {
            do { try await graph.updateEvent(id: event.id, .move(start: start, end: end)) } catch { self.error = error.localizedDescription }
            await load()
        }
    }

    // MARK: Disponibilidade

    /// O que ocupa a agenda (Microsoft + Mac): ignora livre, recusado, cancelado e dia todo que não bloqueia (feriado, aniversário).
    func busy(from start: Date, to end: Date) async throws -> [DateInterval] {
        if !macAccess { macAccess = await mac.requestAccess() }
        let all = try await graph.events(from: start, to: end) + (macAccess ? mac.events(from: start, to: end) : [])
        return all.filter { e in
            !e.isCancelled && e.response != "declined" && e.showAs != "free" && (!e.isAllDay || e.showAs == "busy" || e.showAs == "oof")
        }
        .map { DateInterval(start: $0.start, end: max($0.start, $0.end)) }
    }

    func sendOffer(_ offer: AvailabilityOffer, from me: String) async -> Bool {
        do {
            try await graph.sendMail(to: [Recipient(parsing: offer.recipient)], subject: offer.emailSubject, html: offer.emailHTML(replyTo: me))
            offers.insert(offer, at: 0)
            saveOffers()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func cancelOffer(_ id: String) {
        guard let i = offers.firstIndex(where: { $0.id == id }) else { return }
        offers[i].status = .cancelled
        saveOffers()
    }

    /// Respostas com a referência `[MM-…]` viram evento com convite. Devolve os avisos para o toast.
    func processOfferReplies(_ messages: [StoredMessage]) async -> [String] {
        var notes: [String] = []
        for m in messages {
            guard let ref = AvailabilityOffer.match(subject: m.subject),
                  let i = offers.firstIndex(where: { $0.id == ref.id && $0.status == .waiting }),
                  offers[i].slots.indices.contains(ref.index) else { continue }
            // Marca antes de criar: a próxima sincronização não cria o mesmo evento de novo.
            offers[i].status = .confirmed
            offers[i].chosen = ref.index
            saveOffers()
            let offer = offers[i]
            let start = offer.slots[ref.index]
            let draft = EventDraft(title: offer.title, start: start, end: start.addingTimeInterval(TimeInterval(offer.durationMinutes * 60)),
                                   attendees: [offer.recipient],
                                   notes: "Horário escolhido por \(offer.recipientName) na disponibilidade enviada pelo MasterMail.",
                                   teamsMeeting: offer.teams)
            let when = start.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
            do {
                try await graph.createEvent(draft)
                notes.append("\(offer.recipientName) escolheu \(when): evento criado e convite enviado")
            } catch {
                if let j = offers.firstIndex(where: { $0.id == offer.id }) { offers[j].status = .waiting; offers[j].chosen = nil; saveOffers() }
                notes.append("\(offer.recipientName) escolheu \(when), mas o evento não foi criado: \(error.localizedDescription)")
            }
        }
        // Roda depois da sincronização do Mail: não pede acesso ao calendário fora da agenda (ADR 0009).
        if !notes.isEmpty { await load(requestMacAccess: false) }
        return notes
    }

    private func saveOffers() {
        do { try offerStore.save(offers) } catch { self.error = "Não salvou a disponibilidade enviada: \(error.localizedDescription)" }
    }

    func color(of name: String) -> Color {
        calendars.first { $0.name == name }?.colorHex.flatMap(Color.init(hex:)) ?? .blue
    }

    func events(on day: Date, allDay: Bool? = nil) -> [CalendarEvent] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return events.filter { e in
            (allDay == nil || e.isAllDay == allDay) && !e.isCancelled && !hiddenCalendars.contains(e.calendarName) &&
                e.start < end && (e.end > start || e.start >= start)
        }
        .sorted { ($0.isAllDay ? 0 : 1, $0.start) < ($1.isAllDay ? 0 : 1, $1.start) }
    }
}

extension CalendarEvent {
    var calendarName: String {
        if case let .mac(calendar) = source { return calendar }
        return CalendarModel.microsoftName
    }

    var tint: Color {
        if isCancelled || response == "declined" { return .gray }
        return colorHex.flatMap(Color.init(hex:)) ?? .blue
    }

    var timeRange: String {
        "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
    }

    /// Chave de seleção: o mesmo evento aparece em vários dias (evento longo), só um popover abre.
    func key(on day: Date) -> String { "\(id)|\(Int(Calendar.current.startOfDay(for: day).timeIntervalSince1970))" }
}

extension Color {
    init?(hex: String) {
        guard let v = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) else { return nil }
        self.init(red: Double(v >> 16 & 0xFF) / 255, green: Double(v >> 8 & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: String?
    @State private var creatingAt: Date?
    @State private var creating = false

    private var cal: CalendarModel? { model.calendar }

    var body: some View {
        Group {
            if let cal {
                NavigationSplitView {
                    CalendarSidebar(cal: cal, selected: $selected)
                        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
                } detail: {
                    Group {
                        if cal.mode == .month {
                            MonthGrid(cal: cal, selected: $selected)
                        } else {
                            TimeGrid(cal: cal, selected: $selected) { creatingAt = $0; creating = true }
                        }
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .navigationTitle(title(cal))
                    .navigationSubtitle(subtitle(cal))
                    .toolbar { toolbar(cal) }
                }
                .background { shortcuts(cal) }
                .sheet(isPresented: $creating) { EventEditor(cal: cal, defaultStart: creatingAt ?? cal.anchor, startAt: creatingAt) }
                .onChange(of: creating) { if !creating { creatingAt = nil } }
                .sheet(item: Binding(get: { cal.editRequest }, set: { cal.editRequest = $0 })) { EventEditLoader(cal: cal, request: $0) }
                .alert("Erro", isPresented: Binding(get: { cal.error != nil && !creating && cal.editRequest == nil }, set: { if !$0 { cal.error = nil } })) {
                    Button("OK") { cal.error = nil }
                } message: { Text(cal.error ?? "") }
                .task { await cal.load() }
            } else {
                ContentUnavailableView("Calendário", systemImage: "calendar", description: Text("Entre com a conta para ver a agenda."))
            }
        }
    }

    private func title(_ cal: CalendarModel) -> String {
        let date = cal.mode == .month ? cal.anchor : cal.days[cal.days.count / 2]
        return date.formatted(.dateTime.month(.wide).year()).capitalizedFirst
    }

    private func subtitle(_ cal: CalendarModel) -> String {
        switch cal.mode {
        case .month: ""
        case .day: cal.anchor.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalizedFirst
        case .week:
            "\(cal.interval.start.formatted(.dateTime.day().month())) – \(cal.days.last!.formatted(.dateTime.day().month()))"
        }
    }

    @ToolbarContentBuilder
    private func toolbar(_ cal: CalendarModel) -> some ToolbarContent {
        ToolbarItem(placement: .navigation) { ViewPicker() }
        ToolbarItemGroup {
            if cal.isLoading { ProgressView().controlSize(.small) }
            ControlGroup {
                Button { Task { await cal.shift(-1) } } label: { Label("Anterior", systemImage: "chevron.left") }
                Button("Hoje") { Task { await cal.today() } }
                Button { Task { await cal.shift(1) } } label: { Label("Próximo", systemImage: "chevron.right") }
            }
            Picker("Modo", selection: Binding(get: { cal.mode }, set: { m in Task { await cal.setMode(m) } })) {
                Text("Dia").tag(CalendarModel.Mode.day)
                Text("Semana").tag(CalendarModel.Mode.week)
                Text("Mês").tag(CalendarModel.Mode.month)
            }
            .pickerStyle(.segmented)
            .fixedSize()
            Button { model.availabilityRecipient = "" } label: { Label("Enviar disponibilidade", systemImage: "calendar.badge.clock") }
                .help("Enviar seus horários livres para alguém escolher")
            Button { creatingAt = nil; creating = true } label: { Label("Novo evento", systemImage: "plus") }
        }
    }

    /// Atalhos de uma tecla do 04-ux: d/w/m, t, ←/→, n.
    private func shortcuts(_ cal: CalendarModel) -> some View {
        Group {
            Button("") { Task { await cal.setMode(.day) } }.keyboardShortcut("d", modifiers: [])
            Button("") { Task { await cal.setMode(.week) } }.keyboardShortcut("w", modifiers: [])
            Button("") { Task { await cal.setMode(.month) } }.keyboardShortcut("m", modifiers: [])
            Button("") { Task { await cal.today() } }.keyboardShortcut("t", modifiers: [])
            Button("") { Task { await cal.shift(-1) } }.keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { Task { await cal.shift(1) } }.keyboardShortcut(.rightArrow, modifiers: [])
            Button("") { creatingAt = nil; creating = true }.keyboardShortcut("n", modifiers: [])
        }
        .opacity(0)
        .accessibilityHidden(true)
    }
}

// MARK: Lateral

struct CalendarSidebar: View {
    @Environment(AppModel.self) private var model
    @Bindable var cal: CalendarModel
    @Binding var selected: String?

    var body: some View {
        List {
            DatePicker("Ir para", selection: Binding(get: { cal.anchor }, set: { d in Task { await cal.go(to: d) } }), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)

            Section("Calendários") {
                ForEach(cal.calendars.indices, id: \.self) { i in
                    let item = cal.calendars[i]
                    let visible = !cal.hiddenCalendars.contains(item.name)
                    Button {
                        if visible { cal.hiddenCalendars.insert(item.name) } else { cal.hiddenCalendars.remove(item.name) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: visible ? "checkmark.square.fill" : "square")
                                .foregroundStyle(cal.color(of: item.name))
                                .font(.system(size: 14))
                            Text(item.name).lineLimit(1)
                            Spacer()
                            if item.name != CalendarModel.microsoftName {
                                Image(systemName: "lock").font(.caption2).foregroundStyle(.tertiary).help("Agenda do Mac: só leitura")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                if !cal.macAccess {
                    Text("Libere o acesso em Ajustes do Sistema › Privacidade › Calendários para ver a Agenda do Mac.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Hoje") {
                if cal.upcomingToday.isEmpty {
                    Text("Nada mais na agenda hoje.").font(.callout).foregroundStyle(.secondary)
                }
                ForEach(cal.upcomingToday.prefix(8)) { e in
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 1.5).fill(e.tint).frame(width: 3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(e.title).font(.callout.weight(.medium)).lineLimit(1)
                            Text(e.isAllDay ? "Dia todo" : e.timeRange).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        if let url = e.joinURL, e.start.timeIntervalSinceNow < 15 * 60 { JoinButton(url: url, compact: true) }
                    }
                    .padding(.vertical, 1)
                    .contentShape(Rectangle())
                    .onTapGesture { Task { await cal.go(to: e.start, mode: cal.mode == .month ? .day : nil); selected = e.key(on: e.start) } }
                }
            }

            Section("Disponibilidade enviada") {
                ForEach(cal.offers.filter { $0.status != .cancelled }.prefix(6)) { offer in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: offer.status == .confirmed ? "checkmark.circle.fill" : "clock")
                            .foregroundStyle(offer.status == .confirmed ? Color.green : Color.secondary)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(offer.recipientName).font(.callout.weight(.medium)).lineLimit(1)
                            Text(offer.chosenSlot.map { "\(offer.title) · \($0.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))" }
                                 ?? "\(offer.title) · \(offer.slots.count) horários · aguardando")
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    .contextMenu {
                        Button(offer.status == .waiting ? "Cancelar (ignorar respostas)" : "Tirar da lista") { cal.cancelOffer(offer.id) }
                    }
                }
                Button { model.availabilityRecipient = "" } label: { Label("Enviar disponibilidade…", systemImage: "calendar.badge.clock") }
                    .buttonStyle(.plain).foregroundStyle(Color.accentColor)
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: Dia e semana

struct TimeGrid: View {
    @Bindable var cal: CalendarModel
    @Binding var selected: String?
    let onCreate: (Date) -> Void
    private let hourHeight: CGFloat = 52
    private let gutter: CGFloat = 56

    var body: some View {
        let days = cal.days
        let allDay = days.map { cal.events(on: $0, allDay: true) }
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: gutter)
                ForEach(days, id: \.self) { day in
                    DayHeader(day: day, wide: days.count == 1)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .leading) { Rectangle().fill(.separator).frame(width: 1).padding(.vertical, 6) }
                }
            }
            .frame(height: 44)

            if allDay.contains(where: { !$0.isEmpty }) {
                HStack(alignment: .top, spacing: 0) {
                    Text("dia todo").font(.caption2).foregroundStyle(.secondary)
                        .frame(width: gutter - 8, alignment: .trailing).padding(.trailing, 8).padding(.top, 4)
                    ForEach(Array(zip(days, allDay)), id: \.0) { day, events in
                        VStack(spacing: 2) {
                            ForEach(events.prefix(3)) { e in
                                EventBlock(event: e, compact: true, isSelected: selected == e.key(on: day))
                                    .frame(height: 20)
                                    .eventPopover(e, key: e.key(on: day), selected: $selected, cal: cal)
                            }
                            if events.count > 3 {
                                Text("+\(events.count - 3)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(3)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .overlay(alignment: .leading) { Rectangle().fill(.separator).frame(width: 1) }
                    }
                }
                .background(Color.primary.opacity(0.025))
            }
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    TimelineView(.everyMinute) { context in
                        HStack(alignment: .top, spacing: 0) {
                            HourGutter(hourHeight: hourHeight, width: gutter, now: days.contains { Calendar.current.isDateInToday($0) } ? context.date : nil)
                            ForEach(days, id: \.self) { day in
                                DayColumn(day: day, events: cal.events(on: day, allDay: false), hourHeight: hourHeight, now: context.date,
                                          cal: cal, selected: $selected, onCreate: onCreate)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onAppear { proxy.scrollTo(firstHour(days), anchor: .top) }
                .onChange(of: cal.interval) { proxy.scrollTo(firstHour(days), anchor: .top) }
            }
        }
    }

    private func firstHour(_ days: [Date]) -> Int {
        guard days.contains(where: { Calendar.current.isDateInToday($0) }) else { return 7 }
        return max(0, min(7, Calendar.current.component(.hour, from: Date()) - 2))
    }
}

struct DayHeader: View {
    let day: Date
    let wide: Bool

    var body: some View {
        let isToday = Calendar.current.isDateInToday(day)
        let isWeekend = Calendar.current.isDateInWeekend(day)
        HStack(spacing: 6) {
            Text(day.formatted(.dateTime.weekday(wide ? .wide : .abbreviated)).capitalizedFirst)
                .font(.callout)
                .foregroundStyle(isToday ? Color.red : (isWeekend ? .secondary : .primary))
            Text(day.formatted(.dateTime.day()))
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(isToday ? Color.white : (isWeekend ? Color.secondary : Color.primary))
                .frame(minWidth: 26, minHeight: 26)
                .background { if isToday { Circle().fill(.red) } }
        }
    }
}

struct HourGutter: View {
    let hourHeight: CGFloat
    let width: CGFloat
    let now: Date?

    var body: some View {
        let cal = Calendar.current
        let nowY = now.map { CGFloat($0.timeIntervalSince(cal.startOfDay(for: $0)) / 3600) * hourHeight }
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ForEach(0 ..< 24, id: \.self) { h in Color.clear.frame(height: hourHeight).id(h) }
            }
            ForEach(1 ..< 24, id: \.self) { h in
                let y = CGFloat(h) * hourHeight
                // Esconde a hora cheia que encosta no rótulo de agora, como o Calendário da Apple.
                if nowY.map({ abs($0 - y) > 12 }) ?? true {
                    Text(String(format: "%02d:00", h))
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                        .offset(y: y - 7)
                }
            }
            if let now, let nowY {
                Text(now.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(.red)
                    .padding(.trailing, 8)
                    .offset(y: nowY - 7)
            }
        }
        .frame(width: width, height: 24 * hourHeight, alignment: .topTrailing)
    }
}

struct DayColumn: View {
    let day: Date
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    let now: Date
    let cal: CalendarModel
    @Binding var selected: String?
    let onCreate: (Date) -> Void
    /// Arraste em andamento: deslocamento bruto; o horário mostrado já sai encaixado de 15 em 15 min.
    @State private var drag: (id: String, translation: CGSize, resize: Bool)?

    var body: some View {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        let isToday = calendar.isDateInToday(day)
        let slots = CalendarEvent.slots(for: events)
        ZStack(alignment: .topLeading) {
            grid(isWeekend: calendar.isDateInWeekend(day))
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { point in
                    // Duplo clique no vazio: novo evento na meia hora clicada.
                    let halfHours = (point.y / hourHeight * 2).rounded(.down)
                    onCreate(dayStart.addingTimeInterval(halfHours * 1800))
                }

            GeometryReader { geo in
                let usable = geo.size.width - 8
                ForEach(events) { original in
                    let e = preview(original)
                    let dragging = drag?.id == original.id
                    let slot = slots[original.id] ?? EventSlot(column: 0, columns: 1)
                    let width = dragging ? usable : usable / CGFloat(slot.columns)
                    let top = CGFloat(max(0, e.start.timeIntervalSince(dayStart)) / 3600) * hourHeight
                    let bottom = CGFloat(min(24 * 3600, e.end.timeIntervalSince(dayStart)) / 3600) * hourHeight
                    let height = max(20, bottom - top - 1)
                    let movable = original.canEdit && !original.isAllDay
                    EventBlock(event: e, compact: height < 34, isSelected: selected == original.key(on: day) || dragging, isPast: e.end < now)
                        .frame(width: max(10, width - 2), height: height)
                        .overlay(alignment: .bottom) {
                            if movable {
                                Color.clear.frame(height: 6).contentShape(Rectangle())
                                    .pointerStyle(.frameResize(position: .bottom))
                                    .highPriorityGesture(dragGesture(original, columnWidth: geo.size.width, resize: true))
                            }
                        }
                        .eventPopover(original, key: original.key(on: day), selected: $selected, cal: cal)
                        .gesture(dragGesture(original, columnWidth: geo.size.width, resize: false), including: movable ? .all : .subviews)
                        .shadow(color: .black.opacity(dragging ? 0.25 : 0), radius: 6, y: 2)
                        .offset(x: dragging && drag?.resize == false ? dayShift(columnWidth: geo.size.width) * geo.size.width : 0)
                        .padding(.leading, dragging ? 2 : 2 + CGFloat(slot.column) * width)
                        .padding(.top, top)
                        .zIndex(dragging ? 2 : selected == original.key(on: day) ? 1 : 0)
                }
            }

            if isToday {
                let y = CGFloat(now.timeIntervalSince(dayStart) / 3600) * hourHeight
                HStack(spacing: 0) {
                    Circle().fill(.red).frame(width: 8, height: 8).offset(x: -4)
                    Rectangle().fill(.red).frame(height: 1.5)
                }
                .offset(y: y - 4)
                .allowsHitTesting(false)
            }
        }
        .frame(height: 24 * hourHeight)
    }

    private var snappedMinutes: Int {
        guard let drag else { return 0 }
        return Int((drag.translation.height / hourHeight * 4).rounded()) * 15
    }

    /// Dias inteiros de deslocamento lateral (semana): arrastar meia coluna já troca de dia.
    private func dayShift(columnWidth: CGFloat) -> CGFloat {
        guard let drag, columnWidth > 0 else { return 0 }
        return (drag.translation.width / columnWidth).rounded()
    }

    /// Evento com o horário que vai ficar se o arraste terminar agora.
    private func preview(_ e: CalendarEvent) -> CalendarEvent {
        guard let drag, drag.id == e.id else { return e }
        var p = e
        let delta = TimeInterval(snappedMinutes * 60)
        if drag.resize {
            p.end = max(e.start.addingTimeInterval(15 * 60), e.end.addingTimeInterval(delta))
        } else {
            p.start = e.start.addingTimeInterval(delta)
            p.end = e.end.addingTimeInterval(delta)
        }
        return p
    }

    private func dragGesture(_ e: CalendarEvent, columnWidth: CGFloat, resize: Bool) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                selected = nil
                drag = (e.id, value.translation, resize)
            }
            .onEnded { _ in
                let p = preview(e)
                let days = resize ? 0 : Int(dayShift(columnWidth: columnWidth))
                let cal = Calendar.current
                let start = cal.date(byAdding: .day, value: days, to: p.start)!
                let end = cal.date(byAdding: .day, value: days, to: p.end)!
                drag = nil
                if start != e.start || end != e.end { self.cal.move(e, start: start, end: end) }
            }
    }

    /// Linhas das horas, meias horas tracejadas e fora do expediente (antes das 8, depois das 18) mais escuro.
    private func grid(isWeekend: Bool) -> some View {
        Canvas { ctx, size in
            let shade = GraphicsContext.Shading.color(.primary.opacity(isWeekend ? 0.045 : 0.03))
            ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: 8 * hourHeight)), with: shade)
            ctx.fill(Path(CGRect(x: 0, y: 18 * hourHeight, width: size.width, height: 6 * hourHeight)), with: shade)
            if isWeekend { ctx.fill(Path(CGRect(x: 0, y: 8 * hourHeight, width: size.width, height: 10 * hourHeight)), with: .color(.primary.opacity(0.015))) }
            for h in 0 ... 24 {
                let y = CGFloat(h) * hourHeight
                ctx.stroke(Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: size.width, y: y)) },
                           with: .color(.primary.opacity(0.1)), lineWidth: 1)
                if h < 24 {
                    let half = y + hourHeight / 2
                    ctx.stroke(Path { $0.move(to: CGPoint(x: 0, y: half)); $0.addLine(to: CGPoint(x: size.width, y: half)) },
                               with: .color(.primary.opacity(0.05)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }
            }
            ctx.stroke(Path { $0.move(to: .zero); $0.addLine(to: CGPoint(x: 0, y: size.height)) }, with: .color(.primary.opacity(0.1)), lineWidth: 1)
        }
    }
}

struct EventBlock: View {
    let event: CalendarEvent
    let compact: Bool
    let isSelected: Bool
    var isPast = false
    @State private var hovering = false

    var body: some View {
        let color = event.tint
        let tentative = event.response == "tentativelyAccepted" || event.response == "notResponded" || event.showAs == "tentative"
        let free = event.showAs == "free"
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        VStack(alignment: .leading, spacing: 1) {
            if compact {
                (Text(event.title).fontWeight(.semibold)
                    + Text(event.isAllDay ? "" : "  " + event.start.formatted(date: .omitted, time: .shortened)).foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary))
                    .lineLimit(1)
            } else {
                Text(event.title).fontWeight(.semibold).lineLimit(3)
                Text(event.timeRange).monospacedDigit().foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary).lineLimit(1)
                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin").labelStyle(.titleAndIcon).foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary).lineLimit(1)
                }
            }
        }
        .font(.system(size: 11))
        .strikethrough(event.isCancelled || event.response == "declined")
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.leading, 8).padding(.trailing, 4).padding(.vertical, compact ? 2 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            shape.fill(isSelected ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(hovering ? 0.3 : (free ? 0.05 : tentative ? 0.1 : 0.2))))
                .background(shape.fill(Color(nsColor: .textBackgroundColor)))
        }
        .overlay(alignment: .leading) { if !isSelected { Rectangle().fill(color).frame(width: 3) } }
        .overlay { if tentative && !isSelected { shape.strokeBorder(color.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 2])) } }
        .overlay { if free && !isSelected { shape.strokeBorder(color.opacity(0.5), lineWidth: 1) } }
        .clipShape(shape)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 3) {
                if event.joinURL != nil { Image(systemName: "video.fill") }
                if event.isRecurring { Image(systemName: "arrow.triangle.2.circlepath") }
                if !event.isEditable { Image(systemName: "lock.fill") }
            }
            .font(.system(size: 7, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .padding(4)
        }
        .opacity(isPast && !isSelected ? 0.6 : 1)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
        .help(event.title)
    }
}

extension View {
    /// Clique abre o detalhe apontando para o próprio evento.
    func eventPopover(_ event: CalendarEvent, key: String, selected: Binding<String?>, cal: CalendarModel) -> some View {
        contentShape(Rectangle())
            .onTapGesture { selected.wrappedValue = key }
            .popover(isPresented: Binding(get: { selected.wrappedValue == key }, set: { if !$0, selected.wrappedValue == key { selected.wrappedValue = nil } }),
                     arrowEdge: .trailing) {
                EventDetail(event: event, cal: cal) { selected.wrappedValue = nil }
            }
    }
}

// MARK: Mês

struct MonthGrid: View {
    @Bindable var cal: CalendarModel
    @Binding var selected: String?

    var body: some View {
        let days = cal.days
        let month = Calendar.current.component(.month, from: cal.anchor)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(days.prefix(7), id: \.self) { d in
                    Text(d.formatted(.dateTime.weekday(.abbreviated)).capitalizedFirst)
                        .font(.callout).foregroundStyle(Calendar.current.isDateInWeekend(d) ? Color.secondary : Color.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 10)
                }
            }
            .frame(height: 30)
            Divider()
            GeometryReader { geo in
                let rowHeight = geo.size.height / 6
                VStack(spacing: 0) {
                    ForEach(0 ..< 6, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(days[row * 7 ..< row * 7 + 7], id: \.self) { day in
                                MonthCell(day: day, inMonth: Calendar.current.component(.month, from: day) == month,
                                          events: cal.events(on: day), height: rowHeight, cal: cal, selected: $selected)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MonthCell: View {
    let day: Date
    let inMonth: Bool
    let events: [CalendarEvent]
    let height: CGFloat
    let cal: CalendarModel
    @Binding var selected: String?

    var body: some View {
        let isToday = Calendar.current.isDateInToday(day)
        let fits = max(0, Int((height - 34) / 18))
        let shown = events.count > fits ? max(0, fits - 1) : events.count
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Spacer()
                Text(day.formatted(.dateTime.day()))
                    .font(.callout.weight(isToday ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(isToday ? AnyShapeStyle(Color.white) : (inMonth ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary)))
                    .frame(minWidth: 24, minHeight: 24)
                    .background { if isToday { Circle().fill(.red) } }
            }
            ForEach(events.prefix(shown)) { e in
                MonthEventRow(event: e, isSelected: selected == e.key(on: day))
                    .eventPopover(e, key: e.key(on: day), selected: $selected, cal: cal)
            }
            if events.count > shown {
                Button("mais \(events.count - shown)") { Task { await cal.go(to: day, mode: .day) } }
                    .buttonStyle(.plain).font(.caption.weight(.medium)).foregroundStyle(.secondary).padding(.leading, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .top)
        .background(inMonth ? Color.clear : Color.primary.opacity(0.03))
        .overlay(alignment: .trailing) { Rectangle().fill(.separator).frame(width: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(.separator).frame(height: 1) }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { Task { await cal.go(to: day, mode: .day) } }
    }
}

struct MonthEventRow: View {
    let event: CalendarEvent
    let isSelected: Bool

    var body: some View {
        let color = event.tint
        HStack(spacing: 5) {
            if !event.isAllDay { Circle().fill(isSelected ? Color.white : color).frame(width: 7, height: 7) }
            Text(event.title).lineLimit(1).strikethrough(event.response == "declined")
            Spacer(minLength: 2)
            if !event.isAllDay {
                Text(event.start.formatted(date: .omitted, time: .shortened)).monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
            }
        }
        .font(.system(size: 11, weight: event.isAllDay ? .semibold : .regular))
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 5).frame(height: 16)
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isSelected ? color : (event.isAllDay ? color.opacity(0.22) : .clear))
        }
    }
}

// MARK: Detalhe

struct EventDetail: View {
    let event: CalendarEvent
    let cal: CalendarModel
    let onClose: () -> Void
    @State private var askingDelete = false
    @State private var askingEditScope = false

    private var when: String {
        let c = Calendar.current
        if event.isAllDay {
            let last = c.date(byAdding: .day, value: -1, to: event.end) ?? event.start
            return c.isDate(last, inSameDayAs: event.start) || last < event.start
                ? event.start.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalizedFirst + " · dia todo"
                : "\(event.start.formatted(.dateTime.day().month())) – \(last.formatted(.dateTime.day().month())) · dia todo"
        }
        return event.start.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalizedFirst
    }

    private var status: (String, String, Color)? {
        switch event.response {
        case "accepted": ("Aceito", "checkmark.circle.fill", .green)
        case "tentativelyAccepted": ("Talvez", "questionmark.circle.fill", .orange)
        case "declined": ("Recusado", "xmark.circle.fill", .red)
        case "notResponded": ("Aguardando sua resposta", "envelope.badge", .blue)
        case "organizer": ("Você organiza", "person.crop.circle.badge.checkmark", .secondary)
        default: nil
        }
    }

    private var isOrganizerWithGuests: Bool { event.response == "organizer" && !event.attendees.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(event.tint).frame(width: 4)
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title).font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    Text(when).foregroundStyle(.secondary)
                    if !event.isAllDay { Text(event.timeRange).monospacedDigit().foregroundStyle(.secondary) }
                    if event.isRecurring {
                        Label("Evento que se repete", systemImage: "arrow.triangle.2.circlepath").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            if let url = event.joinURL { JoinButton(url: url) }

            if let status {
                Label(status.0, systemImage: status.1).font(.caption.weight(.medium)).foregroundStyle(status.2)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(status.2.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 7) {
                if let location = event.location, !location.isEmpty { row("mappin.and.ellipse", location) }
                if let organizer = event.organizer, event.response != "organizer" { row("person", "Organizado por \(organizer)") }
                if let minutes = event.reminderMinutes { row("bell", EventEditor.reminderLabel(minutes)) }
                if let showAs = event.showAs, showAs != "busy" { row("circle.dashed", "Mostrar como: \(EventEditor.showAsLabel(showAs))") }
                HStack(spacing: 8) {
                    Circle().fill(event.tint).frame(width: 8, height: 8).frame(width: 16)
                    Text(event.calendarName)
                    if !event.isEditable { Text("· só leitura").foregroundStyle(.secondary) }
                }
                .font(.callout)
            }

            if !event.attendees.isEmpty { attendees }

            if let preview = event.bodyPreview?.trimmingCharacters(in: .whitespacesAndNewlines), !preview.isEmpty {
                Text(preview).font(.callout).foregroundStyle(.secondary).lineLimit(6)
                    .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
            }

            if event.isEditable {
                Divider()
                if event.response != "organizer" && !event.attendees.isEmpty {
                    HStack(spacing: 6) {
                        answer("Aceitar", "accept", current: "accepted", icon: "checkmark")
                        answer("Talvez", "tentativelyAccept", current: "tentativelyAccepted", icon: "questionmark")
                        answer("Recusar", "decline", current: "declined", icon: "xmark")
                    }
                }
                HStack {
                    if let link = event.webLink { Link("Abrir no Outlook", destination: link).font(.callout) }
                    Spacer()
                    if event.canEdit {
                        Button { if event.isRecurring { askingEditScope = true } else { edit(series: false) } } label: { Label("Editar", systemImage: "pencil") }
                    }
                    Button(role: .destructive) { askingDelete = true } label: { Label("Apagar", systemImage: "trash") }
                }
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 330)
        .confirmationDialog(event.isRecurring ? "Apagar evento que se repete" : "Apagar “\(event.title)”?", isPresented: $askingDelete) {
            if event.isRecurring {
                Button("Apagar só este", role: .destructive) { remove(series: false) }
                Button("Apagar toda a série", role: .destructive) { remove(series: true) }
            } else {
                Button(isOrganizerWithGuests ? "Cancelar reunião" : "Apagar", role: .destructive) { remove(series: false) }
            }
        } message: {
            if isOrganizerWithGuests { Text("Os convidados recebem o cancelamento.") }
        }
        .confirmationDialog("Editar evento que se repete", isPresented: $askingEditScope) {
            Button("Só este") { edit(series: false) }
            Button("Toda a série") { edit(series: true) }
        }
    }

    private var attendees: some View {
        let counts = Dictionary(grouping: event.attendees, by: { $0.response ?? "none" }).mapValues(\.count)
        let summary = [("accepted", "aceitaram"), ("tentativelyAccepted", "talvez"), ("declined", "recusaram")]
            .compactMap { key, label in counts[key].map { "\($0) \(label)" } }
        let pending = event.attendees.count - (counts["accepted"] ?? 0) - (counts["tentativelyAccepted"] ?? 0) - (counts["declined"] ?? 0)
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "person.2").foregroundStyle(.secondary).frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.attendees.count == 1 ? "1 convidado" : "\(event.attendees.count) convidados").font(.callout.weight(.medium))
                    Text((summary + (pending > 0 ? ["\(pending) sem resposta"] : [])).joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            ForEach(event.attendees.prefix(8), id: \.self) { a in
                HStack(spacing: 6) {
                    responseIcon(a.response).frame(width: 16)
                    Text(a.name).lineLimit(1)
                    if a.isOptional { Text("opcional").font(.caption2).foregroundStyle(.tertiary) }
                }
                .font(.callout)
                .help(a.address ?? a.name)
            }
            if event.attendees.count > 8 {
                Text("e mais \(event.attendees.count - 8)").font(.caption).foregroundStyle(.secondary).padding(.leading, 22)
            }
        }
    }

    private func responseIcon(_ response: String?) -> some View {
        let (icon, color): (String, Color) = switch response {
        case "accepted": ("checkmark.circle.fill", .green)
        case "tentativelyAccepted": ("questionmark.circle.fill", .orange)
        case "declined": ("xmark.circle.fill", .red)
        default: ("circle.dotted", .secondary)
        }
        return Image(systemName: icon).foregroundStyle(color).font(.system(size: 11))
    }

    private func row(_ icon: String, _ text: String, lines: Int = 2) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 16)
            Text(text).lineLimit(lines).textSelection(.enabled)
        }
        .font(.callout)
    }

    private func answer(_ title: String, _ action: String, current: String, icon: String) -> some View {
        let chosen = event.response == current
        return Button { Task { await cal.respond(event, action); onClose() } } label: {
            Label(title, systemImage: chosen ? icon + ".circle.fill" : icon).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(chosen ? .accentColor : nil)
        .controlSize(.regular)
    }

    private func edit(series: Bool) {
        onClose()
        cal.editRequest = .init(event: event, series: series)
    }

    private func remove(series: Bool) {
        Task { await cal.delete(event, series: series); onClose() }
    }
}

/// Busca corpo e repetição antes de abrir o editor de um evento existente.
struct EventEditLoader: View {
    let cal: CalendarModel
    let request: CalendarModel.EditRequest
    @Environment(\.dismiss) private var dismiss
    @State private var details: EventDetails?
    @State private var failed = false

    var body: some View {
        Group {
            if let details {
                EventEditor(cal: cal, editing: details, series: request.series)
            } else {
                VStack(spacing: 12) {
                    if failed {
                        Text("Não foi possível abrir o evento.").foregroundStyle(.secondary)
                        Button("Fechar") { dismiss() }
                    } else {
                        ProgressView()
                        Text("Abrindo evento…").foregroundStyle(.secondary)
                    }
                }
                .frame(width: 460, height: 200)
            }
        }
        .task {
            details = await cal.details(request.event, series: request.series)
            if details == nil { cal.error = nil; failed = true }
        }
    }
}

struct EventEditor: View {
    let cal: CalendarModel
    @Environment(\.dismiss) private var dismiss
    /// Evento sendo editado (id já é o da série quando `series`); nil = novo.
    private let editing: EventDetails?
    private let series: Bool
    @State private var title = ""
    @State private var start: Date
    @State private var end: Date
    @State private var allDay = false
    @State private var location = ""
    @State private var attendees = ""
    @State private var notes = ""
    @State private var showAs = "busy"
    @State private var reminder: Int? = 15
    @State private var teams = false
    @State private var repeatRule = EventRepeat.none
    @State private var hasUntil = false
    @State private var until: Date
    @State private var isSaving = false

    static let reminderOptions: [Int?] = [nil, 0, 5, 10, 15, 30, 60, 120, 1440]
    static let showAsOptions = ["busy", "tentative", "free", "oof", "workingElsewhere"]

    static func reminderLabel(_ minutes: Int?) -> String {
        switch minutes {
        case nil: "Sem alerta"
        case 0: "Alerta na hora"
        case let m? where m % 1440 == 0: m == 1440 ? "1 dia antes" : "\(m / 1440) dias antes"
        case let m? where m % 60 == 0: m == 60 ? "1 hora antes" : "\(m / 60) horas antes"
        case let m?: "\(m) min antes"
        }
    }

    static func showAsLabel(_ value: String) -> String {
        switch value {
        case "free": "Livre"
        case "tentative": "Provisório"
        case "oof": "Fora do escritório"
        case "workingElsewhere": "Trabalhando em outro lugar"
        default: "Ocupado"
        }
    }

    /// Novo evento. `startAt` = horário exato (duplo clique na grade); sem ele, próxima hora cheia hoje ou 9h no dia escolhido.
    init(cal: CalendarModel, defaultStart: Date, startAt: Date? = nil, prefillTitle: String = "", prefillAttendees: String = "", prefillNotes: String = "") {
        self.cal = cal
        editing = nil
        series = false
        let c = Calendar.current
        let next = c.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? Date()
        let s = startAt ?? (c.isDateInToday(defaultStart) ? next : c.date(bySettingHour: 9, minute: 0, second: 0, of: defaultStart)!)
        _start = State(initialValue: s)
        _end = State(initialValue: c.date(byAdding: .hour, value: 1, to: s)!)
        _until = State(initialValue: c.date(byAdding: .month, value: 3, to: s)!)
        _title = State(initialValue: prefillTitle)
        _attendees = State(initialValue: prefillAttendees)
        _notes = State(initialValue: prefillNotes)
    }

    init(cal: CalendarModel, editing details: EventDetails, series: Bool) {
        self.cal = cal
        editing = details
        self.series = series
        let e = details.event
        let c = Calendar.current
        _title = State(initialValue: e.title)
        _start = State(initialValue: e.start)
        // Dia todo: o Graph guarda o fim como meia-noite do dia seguinte; o editor mostra o último dia.
        _end = State(initialValue: e.isAllDay ? max(e.start, c.date(byAdding: .day, value: -1, to: e.end)!) : e.end)
        _allDay = State(initialValue: e.isAllDay)
        _location = State(initialValue: e.location ?? "")
        _attendees = State(initialValue: Self.attendeeText(e))
        _notes = State(initialValue: details.notes)
        _showAs = State(initialValue: e.showAs ?? "busy")
        _reminder = State(initialValue: e.reminderMinutes)
        _teams = State(initialValue: details.isOnlineMeeting)
        _repeatRule = State(initialValue: details.repeatRule)
        _hasUntil = State(initialValue: details.repeatUntil != nil)
        _until = State(initialValue: details.repeatUntil ?? c.date(byAdding: .month, value: 3, to: e.start)!)
    }

    private static func attendeeText(_ e: CalendarEvent) -> String {
        e.attendees.map { a in a.address.map { a.name == $0 ? $0 : "\(a.name) <\($0)>" } ?? a.name }.joined(separator: ", ")
    }

    /// Repetição só aparece em evento novo ou na série toda (ocorrência avulsa não muda a regra).
    private var showsRepeat: Bool { editing == nil || series }
    private var repeatOptions: [EventRepeat] {
        if editing == nil { return EventRepeat.allCases.filter { $0 != .custom } }
        // Editando a série: o Graph não remove a repetição por PATCH; "personalizada" fica como está.
        return EventRepeat.allCases.filter { $0 != .none && ($0 != .custom || repeatRule == .custom) }
    }

    var body: some View {
        Form {
            Section {
                TextField("Título", text: $title)
                TextField("Local", text: $location)
                Toggle(isOn: $teams) { Label("Reunião do Teams", systemImage: "video") }
                    .disabled(editing?.isOnlineMeeting == true)
            }
            Section {
                Toggle("Dia todo", isOn: $allDay)
                DatePicker("Início", selection: $start, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                DatePicker("Fim", selection: $end, in: start..., displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                if showsRepeat {
                    Picker("Repetir", selection: $repeatRule) {
                        ForEach(repeatOptions, id: \.self) { Text($0.label).tag($0) }
                    }
                    if repeatRule != .none && repeatRule != .custom {
                        Toggle("Termina", isOn: $hasUntil)
                        if hasUntil { DatePicker("Até", selection: $until, in: start..., displayedComponents: .date) }
                    }
                }
            }
            Section {
                RecipientField(prompt: "Convidados", text: $attendees)
                Picker("Alerta", selection: $reminder) {
                    ForEach(Self.reminderOptions, id: \.self) { Text(Self.reminderLabel($0)).tag($0) }
                }
                Picker("Mostrar como", selection: $showAs) {
                    ForEach(Self.showAsOptions, id: \.self) { Text(Self.showAsLabel($0)).tag($0) }
                }
            }
            Section("Notas") {
                TextField("Notas", text: $notes, axis: .vertical).lineLimit(3 ... 8).labelsHidden()
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .disabled(isSaving)
        .interactiveDismissDisabled(isSaving)
        .navigationTitle(editing == nil ? "Novo evento na Agenda Microsoft" : series ? "Editar a série" : "Editar evento")
        .onChange(of: start) { old, new in end = end.addingTimeInterval(new.timeIntervalSince(old)) }
        .alert("Não foi possível salvar o evento", isPresented: Binding(get: { cal.error != nil }, set: { if !$0 { cal.error = nil } })) {
            Button("OK") { cal.error = nil }
        } message: { Text(cal.error ?? "") }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(editing == nil ? "Criar" : "Salvar") { save() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty || end < start || (!allDay && end == start))
            }
        }
    }

    private func save() {
        let c = Calendar.current
        // Dia todo no Graph: começa à meia-noite e termina à meia-noite do dia seguinte ao último.
        let s = allDay ? c.startOfDay(for: start) : start
        let e = allDay ? c.date(byAdding: .day, value: 1, to: c.startOfDay(for: end))! : end
        let parsed = attendees.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let original = editing
        let draft = EventDraft(
            title: title, start: s, end: e, isAllDay: allDay, location: location,
            attendees: original == nil || attendees != Self.attendeeText(original!.event) ? parsed : nil,
            notes: original == nil ? (notes.isEmpty ? nil : notes) : (notes != original!.notes ? notes : nil),
            showAs: showAs, reminderMinutes: reminder,
            teamsMeeting: teams && original?.isOnlineMeeting != true,
            repeatRule: showsRepeat ? repeatRule : .none, repeatUntil: hasUntil ? until : nil
        )
        Task {
            isSaving = true
            defer { isSaving = false }
            let ok = if let original { await cal.update(id: original.event.id, draft) } else { await cal.create(draft) }
            if ok { dismiss() }
        }
    }
}

// MARK: Alertas

/// Notificação do Mac antes dos eventos da Agenda Microsoft de hoje (a Agenda do Mac já avisa sozinha).
/// Opcional (⌘, → Agenda). Reagendada a cada leitura de hoje; o botão "Entrar" abre a reunião.
@MainActor
enum EventReminders {
    static let enabledKey = "eventRemindersEnabled"

    private static let handler = NotificationHandler()
    private static var asked = false

    static func schedule(_ events: [CalendarEvent]) async {
        let center = UNUserNotificationCenter.current()
        center.delegate = handler
        let old = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("evt:") }
        center.removePendingNotificationRequests(withIdentifiers: old)
        // Desligado por padrão: o alerta do evento fica salvo na Microsoft e os outros apps avisam.
        guard UserDefaults.standard.bool(forKey: Self.enabledKey) else { return }
        let now = Date()
        let due = events.compactMap { e -> (CalendarEvent, Date)? in
            guard e.isEditable, !e.isAllDay, e.response != "declined", let minutes = e.reminderMinutes else { return nil }
            let fire = e.start.addingTimeInterval(TimeInterval(-minutes * 60))
            return fire > now ? (e, fire) : nil
        }
        guard !due.isEmpty else { return }
        if !asked {
            asked = true
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        }
        center.setNotificationCategories([UNNotificationCategory(
            identifier: "reuniao", actions: [UNNotificationAction(identifier: "join", title: "Entrar na reunião", options: [.foreground])],
            intentIdentifiers: []
        )])
        for (e, fire) in due {
            let content = UNMutableNotificationContent()
            content.title = e.title
            content.body = [e.timeRange, e.location].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
            content.sound = .default
            if let url = e.joinURL {
                content.categoryIdentifier = "reuniao"
                content.userInfo = ["join": url.absoluteString]
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fire.timeIntervalSince(now)), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "evt:\(e.id)", content: content, trigger: trigger))
        }
    }
}

private final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate, Sendable {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Alerta de evento aparece mesmo com o app na frente; as outras notificações seguem o padrão do sistema.
        notification.request.identifier.hasPrefix("evt:") ? [.banner, .sound] : []
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == "join",
              let link = response.notification.request.content.userInfo["join"] as? String, let url = URL(string: link) else { return }
        await MainActor.run { JoinButton.open(url) }
    }
}
