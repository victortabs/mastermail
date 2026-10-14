import MasterMailCore
import SwiftUI

/// Enviar disponibilidade: mostra os horários livres da agenda, o usuário tira os que não quer e envia por e-mail.
/// A pessoa clica num horário, responde, e o MasterMail cria o evento com convite (ver AvailabilityOffer).
struct AvailabilitySheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let cal: CalendarModel
    @State var recipient: String
    @State private var title = "Reunião"
    @State private var duration = 30
    @State private var step = 60
    @State private var dayCount = 5
    @State private var workStart = 9
    @State private var workEnd = 18
    @State private var teams = true
    @State private var slots: [Date] = []
    @State private var removed: Set<Date> = []
    @State private var loading = false
    @State private var sending = false
    @State private var loadError: String?

    private var chosen: [Date] { slots.filter { !removed.contains($0) } }
    private var validRecipient: Bool { Recipient.parseList(recipient).count == 1 && recipient.contains("@") }
    private var params: [Int] { [duration, step, dayCount, workStart, workEnd] }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Form {
                    Section {
                        RecipientField(prompt: "Para", text: $recipient)
                        TextField("Assunto", text: $title)
                        Toggle(isOn: $teams) { Label("Reunião do Teams", systemImage: "video") }
                    }
                    Section {
                        Picker("Duração", selection: $duration) {
                            ForEach([15, 30, 45, 60, 90, 120], id: \.self) { Text($0 < 60 ? "\($0) min" : $0 % 60 == 0 ? "\($0 / 60) h" : "1 h 30").tag($0) }
                        }
                        Picker("Opções a cada", selection: $step) {
                            Text("30 min").tag(30)
                            Text("1 hora").tag(60)
                        }
                        Picker("Período", selection: $dayCount) {
                            ForEach([3, 5, 10], id: \.self) { Text("\($0) dias úteis").tag($0) }
                        }
                        Picker("Começa às", selection: $workStart) { ForEach(6 ..< 13, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) } }
                        Picker("Termina às", selection: $workEnd) { ForEach(13 ..< 23, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) } }
                    } header: {
                        Text("Horários")
                    } footer: {
                        Text("A pessoa recebe os horários como botões. Ao clicar, ela responde e o evento é criado na sua agenda com convite para ela.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)
                .frame(width: 340)

                Divider()

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Horários livres").font(.headline)
                        Spacer()
                        if loading { ProgressView().controlSize(.small) }
                        if !slots.isEmpty {
                            Text("\(chosen.count) de \(slots.count)").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    Divider()
                    ScrollView { slotList.padding(16) }
                }
                .frame(minWidth: 420, maxWidth: .infinity)
            }

            Divider()
            HStack {
                Text("Clique num horário para tirar ou devolver.").font(.callout).foregroundStyle(.secondary)
                Spacer()
                Button("Cancelar") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Enviar") { send() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(sending || chosen.isEmpty || !validRecipient || title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
        }
        .frame(minWidth: 780, idealWidth: 860, minHeight: 600, idealHeight: 680)
        .disabled(sending)
        .task(id: params) { await reload() }
        .alert("Não foi possível enviar", isPresented: Binding(get: { cal.error != nil }, set: { if !$0 { cal.error = nil } })) {
            Button("OK") { cal.error = nil }
        } message: { Text(cal.error ?? "") }
    }

    @ViewBuilder private var slotList: some View {
        if loading && slots.isEmpty {
            Text("Lendo sua agenda…").foregroundStyle(.secondary)
        } else if let loadError {
            Text(loadError).foregroundStyle(.red)
        } else if slots.isEmpty {
            Text("Nenhum horário livre nesse período e expediente.").foregroundStyle(.secondary)
        } else {
            let days = Dictionary(grouping: slots, by: { Calendar.current.startOfDay(for: $0) }).sorted { $0.key < $1.key }
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(days, id: \.key) { day, times in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            let label = day.formatted(.dateTime.weekday(.wide).day().month(.wide))
                            Text(label.prefix(1).uppercased() + label.dropFirst())
                                .font(.callout.weight(.semibold))
                            Spacer()
                            let allOff = times.allSatisfy(removed.contains)
                            Button(allOff ? "Incluir o dia" : "Tirar o dia") {
                                if allOff { removed.subtract(times) } else { removed.formUnion(times) }
                            }
                            .buttonStyle(.link).font(.caption)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 6)], alignment: .leading, spacing: 6) {
                            ForEach(times, id: \.self) { slotChip($0) }
                        }
                    }
                }
            }
        }
    }

    private func slotChip(_ date: Date) -> some View {
        let on = !removed.contains(date)
        return Button {
            if on { removed.insert(date) } else { removed.remove(date) }
        } label: {
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.callout.weight(on ? .semibold : .regular).monospacedDigit())
                .strikethrough(!on)
                .foregroundStyle(on ? Color.accentColor : Color.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 5)
                .background(on ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.3)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(on ? "Clique para tirar este horário" : "Clique para incluir de volta")
    }

    private func reload() async {
        loading = true
        defer { loading = false }
        let days = Availability.days(from: Date(), count: dayCount, weekdaysOnly: true)
        guard let first = days.first, let last = days.last.flatMap({ Calendar.current.date(byAdding: .day, value: 1, to: $0) }) else { return }
        do {
            let busy = try await cal.busy(from: first, to: last)
            slots = Availability.freeSlots(days: days, busy: busy, workStart: workStart, workEnd: workEnd,
                                           duration: TimeInterval(duration * 60), step: TimeInterval(step * 60), now: Date())
            removed.formIntersection(slots)
            loadError = nil
        } catch {
            if !Task.isCancelled { loadError = "Não deu para ler a agenda: \(error.localizedDescription)" }
        }
    }

    private func send() {
        let offer = AvailabilityOffer(recipient: recipient.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: ",;")),
                                      title: title.trimmingCharacters(in: .whitespaces), durationMinutes: duration, teams: teams, slots: chosen)
        Task {
            sending = true
            defer { sending = false }
            if await cal.sendOffer(offer, from: model.accountEmail) {
                model.showToast("Disponibilidade enviada para \(offer.recipientName). Quando a pessoa escolher, o evento é criado.")
                dismiss()
            }
        }
    }
}

/// "Entrar na reunião": Teams de trabalho abre direto no app; o resto (Teams pessoal, Zoom, Meet…) abre o link.
/// Clique com o botão direito dá as outras opções.
struct JoinButton: View {
    let url: URL
    var compact = false

    var body: some View {
        Button { Self.open(url) } label: {
            Label(compact ? "Entrar" : "Entrar na reunião", systemImage: "video.fill").frame(maxWidth: compact ? nil : .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(compact ? .small : .large)
        .help("Entrar na reunião (botão direito: outras opções)")
        .contextMenu {
            if let app = CalendarEvent.teamsAppURL(for: url) {
                Button("Abrir no app do Teams") { NSWorkspace.shared.open(app) }
            }
            Button("Abrir o link no navegador") { NSWorkspace.shared.open(url) }
            Button("Copiar link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
        }
    }

    static func open(_ url: URL) {
        if let app = CalendarEvent.teamsAppURL(for: url), NSWorkspace.shared.urlForApplication(toOpen: app) != nil {
            NSWorkspace.shared.open(app)
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}
