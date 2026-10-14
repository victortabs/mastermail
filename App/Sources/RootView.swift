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
            case .restoringSession:
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Reconectando sua conta…")
                }.padding(40)
            case .sessionUnavailable:
                VStack(spacing: 16) {
                    Text("Sua conta continua salva.").font(.headline)
                    Text("Não foi possível conectar agora. Verifique sua conexão; tentaremos novamente automaticamente.")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Tentar novamente") { Task { await model.restoreSession() } }
                        .keyboardShortcut(.defaultAction)
                    Button("Desconectar conta", role: .destructive) { Task { await model.signOut() } }
                }.frame(maxWidth: 440).padding(40)
            case let .signedIn(account):
                switch model.view {
                case .mail: MailboxView(account: account)
                case .calendar: CalendarView()
                case .people: PeopleView()
                }
            }
        }
        .sheet(item: $model.availabilityRecipient) { recipient in
            if let cal = model.calendar { AvailabilitySheet(cal: cal, recipient: recipient) }
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
            if let url = model.adminConsentURL {
                AdminConsentHelp(url: url)
            }
        }
        .padding(40)
    }
}

/// A Microsoft bloqueia o consentimento de usuário para e-mail desde nov/2025: o TI precisa aprovar uma vez.
struct AdminConsentHelp: View {
    let url: URL
    @State private var copied = false

    private var message: String {
        """
        Oi, preciso que você aprove o MasterMail para a nossa organização no Microsoft 365. \
        É um cliente de e-mail open source (GPL) que roda só no meu Mac e acessa minha caixa pelo Microsoft Graph \
        com as permissões Mail.ReadWrite, Mail.Send, Calendars.ReadWrite, Contacts.Read, User.Read e offline_access. \
        Basta abrir este link com uma conta de administrador e clicar em Aceitar:
        \(url.absoluteString)
        """
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sua organização exige aprovação do administrador.", systemImage: "lock.shield").font(.headline)
            Text("Mande o texto abaixo para o TI. Depois da aprovação, clique em Entrar de novo.").font(.caption).foregroundStyle(.secondary)
            Text(message).font(.caption).textSelection(.enabled).padding(8).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            HStack {
                Button(copied ? "Copiado" : "Copiar texto") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                    copied = true
                }
                Link("Abrir o link de aprovação (se você for o admin)", destination: url).font(.caption)
            }
        }
        .frame(maxWidth: 520)
    }
}

/// Para usar um id de mensagem como item de `.sheet(item:)`.
extension String: @retroactive Identifiable {
    public var id: String { self }
}
