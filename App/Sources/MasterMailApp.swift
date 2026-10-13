import SwiftUI

/// Configurações (⌘,): assinatura. A IA entra aqui também.
struct SettingsView: View {
    @AppStorage("signatureHTML") private var signature = ""

    var body: some View {
        Form {
            Section("Assinatura") {
                Text("Cole o HTML copiado do Outlook, ou escreva texto simples (quebras de linha viram linhas).")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $signature).frame(minHeight: 160).font(.body.monospaced())
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 320)
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
        Settings { SettingsView() }
        .commands {
            CommandMenu("Visualizar") {
                Button("Mail") { model.view = .mail }.keyboardShortcut("1", modifiers: .command)
                Button("Calendário") { model.view = .calendar }.keyboardShortcut("2", modifiers: .command)
                Button("Pessoas") { model.view = .people }.keyboardShortcut("3", modifiers: .command)
            }
        }
    }
}
