import MasterMailCore
import SwiftUI

/// Regras aprendidas das Explicações. "Automática" = aplica sem perguntar (requisito: promovida pelo usuário).
struct RulesList: View {
    @Environment(AppModel.self) private var model
    @State private var rules: [Rule] = []

    var body: some View {
        if rules.isEmpty {
            Text("Nenhuma regra ainda. Na Triagem, `n` cria uma a partir da sua explicação.").font(.caption).foregroundStyle(.secondary)
                .onAppear(perform: reload)
        } else {
            ForEach(rules) { rule in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(field(rule.field)) \(rule.value) → \(rule.tipo.flatMap(Tipo.init(rawValue:))?.label ?? rule.pastaLocal ?? rule.categoria ?? "")").font(.callout)
                        if let why = rule.explanation, !why.isEmpty { Text(why).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                        Text("usada \(rule.hits)×").font(.caption2).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Toggle("Automática", isOn: Binding(get: { rule.automatic }, set: { on in
                        var r = rule; r.automatic = on; _ = try? model.store.saveRule(r); reload()
                    })).toggleStyle(.switch).controlSize(.mini)
                    Button(role: .destructive) { if let id = rule.id { try? model.store.deleteRule(id: id); reload() } } label: { Image(systemName: "trash") }.buttonStyle(.plain)
                }
            }
            .onAppear(perform: reload)
        }
    }

    private func field(_ f: Rule.Field) -> String {
        switch f {
        case .sender: "remetente"
        case .domain: "domínio"
        case .subjectContains: "assunto contém"
        }
    }

    private func reload() { rules = (try? model.store.rules()) ?? [] }
}

/// Configurações (⌘,): assinatura. A IA entra aqui também.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("signatureHTML") private var signature = ""
    @State private var ai = AISettings()

    var body: some View {
        Form {
            Section("Assinatura") {
                Text("Cole o HTML copiado do Outlook, ou escreva texto simples (quebras de linha viram linhas).")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $signature).frame(minHeight: 120).font(.body.monospaced())
            }
            Section("Regras (zero tokens: resolvem antes de qualquer modelo)") {
                RulesList()
            }
            Section("IA (ADR 0004: Regra → modelo local → nuvem com sua chave)") {
                Toggle("Modelo local (Apple Intelligence)", isOn: $ai.localEnabled)
                Text(FoundationModelsProvider.isAvailable ? "Disponível neste Mac." : "Indisponível neste Mac: Apple Intelligence desligada ou modelo não baixado.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Nuvem via OpenRouter (envia remetente, assunto e trecho de cada mensagem nova)", isOn: $ai.cloudEnabled)
                SecureField("Chave da OpenRouter", text: $ai.openRouterKey)
                TextField("Modelo", text: $ai.openRouterModel)
                TextField("Modelo para o Organizador", text: $ai.openRouterHeavyModel)
                Text("A chave fica só neste Mac, num arquivo com permissão restrita. Nunca vai para o repositório.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 600, height: 680)
        .onAppear { ai = model.aiSettings.load() }
        .onChange(of: ai) { _, new in model.updateAISettings(new) }
    }
}

@main
struct MasterMailApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .frame(minWidth: 900, minHeight: 560)
        }
        Settings { SettingsView().environment(model) }
        .commands {
            CommandMenu("Visualizar") {
                Button("Mail") { model.view = .mail }.keyboardShortcut("1", modifiers: .command)
                Button("Calendário") { model.view = .calendar }.keyboardShortcut("2", modifiers: .command)
                Button("Pessoas") { model.view = .people }.keyboardShortcut("3", modifiers: .command)
            }
        }
    }
}
