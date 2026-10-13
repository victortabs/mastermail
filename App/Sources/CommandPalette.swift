import SwiftUI

struct PaletteCommand: Identifiable {
    let id = UUID()
    let name: String
    let keys: String
    let run: () -> Void

    init(_ name: String, _ keys: String, run: @escaping () -> Void) {
        self.name = name
        self.keys = keys
        self.run = run
    }
}

/// ⌘K: todo comando com seu atalho ao lado (docs/04-ux.md).
struct CommandPalette: View {
    @Environment(\.dismiss) private var dismiss
    let commands: [PaletteCommand]
    @State private var query = ""
    @FocusState private var focused: Bool

    private var matches: [PaletteCommand] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? commands : commands.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        VStack(spacing: 8) {
            TextField("Comando…", text: $query)
                .textFieldStyle(.roundedBorder).font(.title3).focused($focused)
                .onSubmit { if let first = matches.first { dismiss(); first.run() } }
                .onExitCommand { dismiss() }
            List(matches) { c in
                Button { dismiss(); c.run() } label: {
                    HStack { Text(c.name); Spacer(); Text(c.keys).font(.caption.monospaced()).foregroundStyle(.secondary) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(height: 300)
        }
        .padding().frame(width: 440)
        .onAppear { focused = true }
    }
}

/// `?`: a tabela de atalhos de docs/04-ux.md.
struct ShortcutsHelp: View {
    @Environment(\.dismiss) private var dismiss

    private let rows: [(String, String)] = [
        ("j / k", "próxima / anterior"), ("Enter / Esc", "entrar / sair da Conversa"), ("o / ⇧O", "expandir mensagem / todas"),
        ("e", "Arquivar"), ("#", "Apagar"), ("v", "Pasta local"), ("h", "Adiar"), ("u", "lida / não lida"), ("s", "sinalizar"),
        ("r", "Responder (a todos)"), ("⌘R", "Responder ao remetente"), ("f", "Encaminhar"), ("c / ⌘N", "nova mensagem"),
        ("⌘↩", "enviar (10 s para desfazer)"), ("z", "desfazer"), ("/", "buscar"), ("⌘K", "paleta de comandos"),
        ("⌘1 ⌘2 ⌘3", "Mail / Calendário / Pessoas"), ("t ← →  n", "no Calendário: hoje, navegar, novo evento"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Atalhos").font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                ForEach(rows, id: \.0) { keys, action in
                    GridRow { Text(keys).font(.body.monospaced()).foregroundStyle(.secondary); Text(action) }
                }
            }
            HStack { Spacer(); Button("Fechar") { dismiss() }.keyboardShortcut(.cancelAction) }
        }
        .padding().frame(width: 420)
    }
}
