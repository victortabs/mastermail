import SwiftUI

@main
struct MasterMailApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .frame(minWidth: 900, minHeight: 560)
        }
        .commands {
            CommandMenu("Visualizar") {
                Button("Mail") { model.view = .mail }.keyboardShortcut("1", modifiers: .command)
                Button("Calendário") { model.view = .calendar }.keyboardShortcut("2", modifiers: .command)
                Button("Pessoas") { model.view = .people }.keyboardShortcut("3", modifiers: .command)
            }
        }
    }
}
