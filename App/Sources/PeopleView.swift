import MasterMailCore
import SwiftUI

/// Pessoas (⌘3): Organizações à esquerda, Contatos da escolhida no meio, mensagens trocadas com ela à direita.
struct PeopleView: View {
    @Environment(AppModel.self) private var model
    @State private var organizations: [Organization] = []
    @State private var contacts: [Contact] = []
    @State private var messages: [StoredMessage] = []
    @State private var selected: Organization.ID?
    @State private var messageSelection: StoredMessage.ID?
    @State private var filter = ""
    @State private var renaming: Organization?
    @State private var renameTo = ""
    @State private var merging: Organization?
    @State private var mergeInto = ""
    /// Contatos salvos na conta: uma leitura do Graph por execução do app.
    @MainActor private static var savedRefreshed = false

    private var filtered: [Organization] {
        let q = filter.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? organizations : organizations.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.domain.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationSplitView {
            List(filtered, selection: $selected) { org in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(org.name).fontWeight(.medium).lineLimit(1)
                        Spacer()
                        Text("\(org.messageCount)").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(org.domain).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .tag(org.id)
                .contextMenu {
                    Button("Renomear…") { renameTo = org.name; renaming = org }
                    Button("Fundir em…") { mergeInto = organizations.first { $0.id != org.id }?.id ?? ""; merging = org }
                        .disabled(organizations.count < 2)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                TextField("Filtrar organizações", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .padding(8)
                    .background(.bar)
            }
            .overlay {
                if organizations.isEmpty { ContentUnavailableView("Nenhuma organização", systemImage: "building.2", description: Text("As Organizações nascem das mensagens indexadas.")) }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 240)
        } content: {
            List(contacts) { c in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(c.name.isEmpty ? c.address : c.name).fontWeight(.medium).lineLimit(1)
                        if c.isSaved { Image(systemName: "person.crop.circle.badge.checkmark").font(.caption).foregroundStyle(.secondary).help("Salvo na conta") }
                        Spacer()
                        Text("\(c.messageCount)").font(.caption).foregroundStyle(.secondary)
                    }
                    if !c.name.isEmpty { Text(c.address).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                }
                .padding(.vertical, 2)
                .contextMenu {
                    Button("Enviar disponibilidade…") { model.availabilityRecipient = c.name.isEmpty ? c.address : "\(c.name) <\(c.address)>" }
                }
            }
            .overlay {
                if selected == nil { ContentUnavailableView("Nenhuma organização escolhida", systemImage: "person.2") }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 280)
        } detail: {
            List(messages, selection: $messageSelection) { MessageRow(message: $0) }
                .overlay {
                    if selected != nil, messages.isEmpty { ContentUnavailableView("Sem mensagens", systemImage: "tray") }
                }
        }
        .navigationTitle("Pessoas")
        .navigationSubtitle(selectedOrganization.map { "\($0.name) · \($0.domain)" } ?? "")
        .toolbar { ToolbarItem(placement: .navigation) { ViewPicker() } }
        .task { await load() }
        .onChange(of: selected) { _, _ in loadSelection() }
        .onChange(of: messageSelection) { _, id in
            guard let message = messages.first(where: { $0.id == id }) else { return }
            messageSelection = nil
            model.view = .mail
            Task { await model.open(message) }
        }
        .alert("Renomear organização", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Nome", text: $renameTo)
            Button("Renomear") {
                if let org = renaming { try? model.store.renameOrganization(domain: org.domain, name: renameTo); reloadOrganizations() }
                renaming = nil
            }
            Button("Cancelar", role: .cancel) { renaming = nil }
        }
        .sheet(item: $merging) { org in
            VStack(alignment: .leading, spacing: 12) {
                Text("Fundir \(org.name) em").font(.headline)
                Picker("Organização", selection: $mergeInto) {
                    ForEach(organizations.filter { $0.id != org.id }) { Text("\($0.name) (\($0.domain))").tag($0.id) }
                }
                .labelsHidden()
                HStack {
                    Spacer()
                    Button("Cancelar", role: .cancel) { merging = nil }
                    Button("Fundir") {
                        try? model.store.mergeOrganization(domain: org.domain, into: mergeInto)
                        if selected == org.id { selected = mergeInto }
                        reloadOrganizations()
                        loadSelection()
                        merging = nil
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(mergeInto.isEmpty)
                }
            }
            .padding(20)
            .frame(width: 360)
        }
    }

    private var selectedOrganization: Organization? { organizations.first { $0.id == selected } }

    private func load() async {
        guard case let .signedIn(account) = model.phase else { return }
        let store = model.store
        // Recálculo fora da main thread: varre o índice inteiro.
        _ = try? await Task.detached { try store.refreshPeople(me: account) }.value
        reloadOrganizations()
        if !Self.savedRefreshed, let client = model.client, let saved = try? await client.savedContacts() {
            Self.savedRefreshed = true
            try? store.markSaved(saved)
            reloadOrganizations()
            loadSelection()
        }
    }

    private func reloadOrganizations() {
        organizations = (try? model.store.organizations()) ?? []
    }

    private func loadSelection() {
        guard let selected else { contacts = []; messages = []; return }
        contacts = (try? model.store.contacts(domain: selected)) ?? []
        messages = (try? model.store.messages(domain: selected)) ?? []
    }
}
