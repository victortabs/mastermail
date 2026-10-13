import MasterMailCore
import SwiftUI

/// Organizador: a proposta (do Haiku ou de um agente externo) vira Sugestão. O usuário marca o que aceita e aplica.
struct OrganizerSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var plan: OrganizationPlan?
    @State private var acceptedRules: Set<String> = []
    @State private var acceptedFolders: Set<String> = []
    @State private var moveExisting = true
    @State private var generating = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Organizar a caixa").font(.title2.bold())
                Spacer()
                Button(generating ? "Gerando…" : "Gerar proposta nova com o modelo") { Task { await generate() } }
                    .disabled(generating)
            }
            if let plan {
                Text(plan.summary).font(.callout).foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pastas locais (\(acceptedFolders.count)/\(plan.folders.count))").font(.headline)
                            Spacer()
                            Button("Todas") { acceptedFolders = Set(plan.folders.map(\.id)) }.controlSize(.mini)
                        }
                        List(plan.folders) { f in
                            Toggle(isOn: Binding(get: { acceptedFolders.contains(f.id) }, set: { on in if on { acceptedFolders.insert(f.id) } else { acceptedFolders.remove(f.id) } })) {
                                VStack(alignment: .leading) {
                                    Text(f.name).fontWeight(.medium)
                                    Text(f.description).font(.caption).foregroundStyle(.secondary)
                                    Text(f.domains.joined(separator: ", ")).font(.caption2).foregroundStyle(.tertiary).lineLimit(2)
                                }
                            }
                        }
                        .frame(minWidth: 260)
                        Text("Categorias sugeridas: " + plan.categories.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Regras (\(acceptedRules.count)/\(plan.rules.count))").font(.headline)
                            Spacer()
                            Button("Todas") { acceptedRules = Set(plan.rules.map(\.id)) }.controlSize(.mini)
                            Button("Só ruído") { acceptedRules = Set(plan.rules.filter { Tipo(lenient: $0.tipo)?.isRuido == true }.map(\.id)) }.controlSize(.mini)
                        }
                        List(plan.rules) { r in
                            Toggle(isOn: Binding(get: { acceptedRules.contains(r.id) }, set: { on in if on { acceptedRules.insert(r.id) } else { acceptedRules.remove(r.id) } })) {
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 6) {
                                        Text(r.value).fontWeight(.medium)
                                        Badge(Tipo(lenient: r.tipo)?.label ?? r.tipo, Tipo(lenient: r.tipo)?.isRuido == true ? .gray : .green)
                                        if let folder = r.pastaLocal { Label(folder, systemImage: "folder").font(.caption) }
                                    }
                                    Text(r.reason).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                            }
                        }
                    }
                }
                Toggle("Mover para as pastas as mensagens que já estão na caixa (vai para o servidor em segundo plano)", isOn: $moveExisting)
                Text("Regras aceitas viram automáticas: o ruído coberto por elas sai da Caixa de entrada direto para \"Ruído\", sem passar pela Triagem. Dá para mudar em ⌘, → Regras.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("Sem proposta ainda", systemImage: "wand.and.stars", description: Text("Gere uma com o modelo (precisa da nuvem ligada em ⌘, → IA) ou deixe um agente externo gravar organization-plan.json em Application Support/MasterMail."))
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
            HStack {
                Spacer()
                Button("Fechar") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Aplicar selecionados") { apply() }
                    .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                    .disabled(plan == nil || (acceptedRules.isEmpty && acceptedFolders.isEmpty))
            }
        }
        .padding()
        .frame(minWidth: 820, minHeight: 600)
        .onAppear(perform: load)
    }

    private func load() {
        plan = model.planStore.load()
        if let plan {
            acceptedRules = Set(plan.rules.map(\.id))
            acceptedFolders = Set(plan.folders.map(\.id))
        }
    }

    private func generate() async {
        generating = true
        defer { generating = false }
        do {
            plan = try await model.generatePlan()
            if let plan {
                acceptedRules = Set(plan.rules.map(\.id))
                acceptedFolders = Set(plan.folders.map(\.id))
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func apply() {
        guard let plan else { return }
        let subset = OrganizationPlan(
            rules: plan.rules.filter { acceptedRules.contains($0.id) },
            folders: plan.folders.filter { acceptedFolders.contains($0.id) },
            categories: plan.categories, summary: plan.summary
        )
        Task {
            await model.applyPlan(subset, moveExisting: moveExisting)
            model.planStore.clear()
            dismiss()
        }
    }
}
