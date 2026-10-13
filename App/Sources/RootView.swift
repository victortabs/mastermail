import MasterMailCore
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Group {
            switch model.phase {
            case .needsClientID: ClientIDView()
            case .signedOut: SignInView()
            case let .signedIn(account):
                switch model.view {
                case .mail: MailboxView(account: account)
                case .calendar: CalendarView()
                case .people: ContentUnavailableView("Pessoas", systemImage: "person.2", description: Text("Organizações e Contatos: em construção."))
                }
            }
        }
        .alert("Erro", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct ClientIDView: View {
    @Environment(AppModel.self) private var model
    @State private var clientID = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("MasterMail").font(.largeTitle.bold())
            Text("Cole o Client ID do app registrado no Entra (ver docs/03-entra.md).")
                .foregroundStyle(.secondary)
            TextField("00000000-0000-0000-0000-000000000000", text: $clientID)
                .textFieldStyle(.roundedBorder)
                .frame(width: 380)
                .onSubmit { model.saveClientID(clientID) }
            Button("Continuar") { model.saveClientID(clientID) }
                .keyboardShortcut(.defaultAction)
                .disabled(clientID.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(40)
    }
}

struct SignInView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 16) {
            Text("MasterMail").font(.largeTitle.bold())
            Text("Conecte sua conta Microsoft 365.").foregroundStyle(.secondary)
            Button("Entrar com a Microsoft") { Task { await model.signIn() } }
                .keyboardShortcut(.defaultAction)
        }
        .padding(40)
    }
}

/// Para usar um id de mensagem como item de `.sheet(item:)`.
extension String: @retroactive Identifiable {
    public var id: String { self }
}
