import MasterMailCore
import SwiftUI

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
            Section("IA (ADR 0004: Regra → modelo local → nuvem com sua chave)") {
                Toggle("Modelo local (Apple Intelligence)", isOn: $ai.localEnabled)
                Text(FoundationModelsProvider.isAvailable ? "Disponível neste Mac." : "Indisponível neste Mac: Apple Intelligence desligada ou modelo não baixado.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Nuvem via OpenRouter (envia remetente, assunto e trecho de cada mensagem nova)", isOn: $ai.cloudEnabled)
                SecureField("Chave da OpenRouter", text: $ai.openRouterKey)
                TextField("Modelo", text: $ai.openRouterModel)
                Text("A chave fica só neste Mac, num arquivo com permissão restrita. Nunca vai para o repositório.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 520)
        .onAppear { ai = model.aiSettings.load() }
        .onChange(of: ai) { _, new in try? model.aiSettings.save(new) }
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
