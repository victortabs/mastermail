import MasterMailCore
import SwiftUI

/// Campo de destinatários ("Nome <a@b>, c@d") com autocompletar do Índice local para o trecho depois da última vírgula.
/// Tab ou Enter aceita a primeira sugestão.
struct RecipientField: View {
    @Environment(AppModel.self) private var model
    var prompt = "Para"
    @Binding var text: String
    @State private var suggestions: [Contact] = []
    @FocusState private var focused: Bool

    var body: some View {
        TextField(prompt, text: $text)
            .focused($focused)
            .onChange(of: text) { _, _ in
                suggestions = focused ? ((try? model.store.suggestRecipients(prefix: token)) ?? []) : []
            }
            .onChange(of: focused) { _, isFocused in if !isFocused { suggestions = [] } }
            .onKeyPress(.tab) { accept() ? .handled : .ignored }
            .onSubmit { _ = accept() }
            .popover(isPresented: Binding(get: { !suggestions.isEmpty }, set: { if !$0 { suggestions = [] } }), arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { c in
                        Button { _ = accept(c) } label: {
                            VStack(alignment: .leading) {
                                Text(c.name.isEmpty ? c.address : c.name)
                                if !c.name.isEmpty { Text(c.address).font(.caption).foregroundStyle(.secondary) }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
                .frame(width: 300)
            }
    }

    /// Trecho sendo digitado: o que vem depois da última vírgula.
    private var token: String {
        String(text.split(separator: ",", omittingEmptySubsequences: false).last ?? "").trimmingCharacters(in: .whitespaces)
    }

    private func accept(_ contact: Contact? = nil) -> Bool {
        guard let contact = contact ?? suggestions.first else { return false }
        var parts = text.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        parts.removeLast()
        text = (parts.filter { !$0.isEmpty } + [contact.display]).joined(separator: ", ") + ", "
        suggestions = []
        return true
    }
}
