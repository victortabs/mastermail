import Foundation
@testable import MasterMailCore
import Testing

/// Devolve sempre a mesma resposta e conta quantas vezes foi chamado.
final class FakeProvider: AIProvider, @unchecked Sendable {
    let name = "fake"
    let reply: String
    private(set) var calls = 0
    init(_ reply: String) { self.reply = reply }
    func complete(system: String, user: String, maxTokens: Int) async throws -> String {
        calls += 1
        return reply
    }
}

struct AITests {
    private func sample(id: String, subject: String = "Assunto", from: String = "ana@bdil.com.br", body: String = "Olá") -> StoredMessage {
        let json = """
        {"id":"\(id)","subject":"\(subject)","from":{"emailAddress":{"name":"Ana","address":"\(from)"}},
         "receivedDateTime":"2026-10-13T12:00:00Z","isRead":false,"hasAttachments":false,
         "body":{"contentType":"text","content":"\(body)"}}
        """
        return StoredMessage(message: try! GraphClient.decoder.decode(Message.self, from: Data(json.utf8)), folder: "inbox")
    }

    private func settings() -> AISettingsStore {
        AISettingsStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("ai-\(UUID().uuidString).json"))
    }

    @Test func parsesStrictJSON() throws {
        let c = try Classifier.parse(#"{"tipo":"financeiro","importante":true,"justificativa":"Boleto vence amanhã.","categoria":"Banco"}"#)
        #expect(c == Classification(tipo: .financeiro, importante: true, justificativa: "Boleto vence amanhã.", categoria: "Banco"))
    }

    @Test func parsesJSONWrappedInProseAndLenientTipo() throws {
        let text = "Claro! Aqui está:\n```json\n{\"tipo\":\"Notificação\",\"importante\":false,\"justificativa\":\"Aviso automático.\",\"categoria\":null}\n```\nEspero ter ajudado."
        let c = try Classifier.parse(text)
        #expect(c.tipo == .notificacao)
        #expect(c.categoria == nil)
        #expect(c.tipo.isRuido)
        #expect(Tipo.pessoa.isRuido == false && Tipo.convite.isRuido == false)
        #expect(throws: AIError.self) { try Classifier.parse("sem json aqui") }
        #expect(throws: AIError.self) { try Classifier.parse(#"{"tipo":"outra"}"#) }
    }

    @Test func promptIsCompact() {
        let m = sample(id: "1", subject: "Fatura", body: String(repeating: "x ", count: 1000))
        let p = Classifier.prompt(for: m)
        #expect(p.contains("Assunto: Fatura"))
        #expect(p.count < 800)
    }

    @Test func ruleMatchingPrecedence() {
        let m = sample(id: "1", subject: "Fatura outubro", from: "Cobranca@Banco.com")
        let subject = Rule(field: .subjectContains, value: "fatura", tipo: .promocao)
        let domain = Rule(field: .domain, value: "banco.com", tipo: .notificacao)
        let sender = Rule(field: .sender, value: "cobranca@banco.com", tipo: .financeiro)
        #expect(RulesEngine.match(m, rules: [subject, domain, sender])?.tipo == "financeiro")
        #expect(RulesEngine.match(m, rules: [subject, domain])?.tipo == "notificacao")
        #expect(RulesEngine.match(m, rules: [subject])?.tipo == "promocao")
        #expect(RulesEngine.match(m, rules: [Rule(field: .domain, value: "outro.com")]) == nil)
    }

    @Test func ruleBuilderFallbackUsesDomainAndCurrentTipo() async {
        var m = sample(id: "1", from: "no-reply@banco.com")
        m.tipo = "financeiro"
        let r = await RuleBuilder.fromExplanation("é o aviso do banco", message: m, provider: nil)
        #expect(r.field == .domain && r.value == "banco.com" && r.tipo == "financeiro" && r.explanation == "é o aviso do banco")
        let viaModel = await RuleBuilder.fromExplanation("x", message: m, provider: FakeProvider(#"{"field":"sender","value":"No-Reply@banco.com","tipo":"notificacao","categoria":null}"#))
        #expect(viaModel.field == .sender && viaModel.value == "no-reply@banco.com" && viaModel.tipo == "notificacao" && viaModel.categoria == nil)
    }

    @Test func triageAndInboxQueries() throws {
        let store = try MailStore.inMemory()
        try store.upsert([sample(id: "p"), sample(id: "n"), sample(id: "u"), sample(id: "f")])
        try store.saveClassification(id: "p", Classification(tipo: .pessoa, justificativa: "j"))
        try store.saveClassification(id: "n", Classification(tipo: .newsletter, justificativa: "j"))
        try store.saveClassification(id: "f", Classification(tipo: .financeiro, importante: true, justificativa: "j"), byRule: true)
        #expect(Set(try store.inboxMessages(folder: "inbox").map(\.id)) == ["p", "u"])
        #expect(Set(try store.triage(folder: "inbox").map(\.id)) == ["n", "f"])
        #expect(try store.unclassified(in: "inbox").map(\.id) == ["u"])
        #expect(try store.importantUnread().map(\.id) == ["f"])
        #expect(try store.message(id: "f")?.justificativa == "Regra: j")
        try store.confirmTriage(id: "n")
        #expect(try store.triage(folder: "inbox").map(\.id) == ["f"])
        try store.setLocalFolder(id: "f", "Banco")
        #expect(try store.triage(folder: "inbox").isEmpty)
        // Re-sincronizar a mensagem não apaga a classificação.
        try store.upsert([sample(id: "p", subject: "novo assunto")])
        let p = try store.message(id: "p")
        #expect(p?.subject == "novo assunto" && p?.tipo == "pessoa" && p?.classifiedAt != nil)
    }

    @Test func rulesPersist() throws {
        let store = try MailStore.inMemory()
        let saved = try store.saveRule(Rule(field: .domain, value: "Banco.com", tipo: .financeiro, explanation: "banco"))
        #expect(saved.id != nil)
        #expect(try store.rules().map(\.value) == ["banco.com"])
        try store.deleteRule(id: saved.id!)
        #expect(try store.rules().isEmpty)
    }

    @Test func pipelineUsesRuleBeforeProvider() async throws {
        let store = try MailStore.inMemory()
        try store.upsert([sample(id: "r", from: "aviso@banco.com"), sample(id: "m", from: "joao@cliente.com")])
        try store.saveRule(Rule(field: .domain, value: "banco.com", tipo: .financeiro, explanation: "é o banco"))
        let fake = FakeProvider(#"{"tipo":"pessoa","importante":false,"justificativa":"Cliente escreveu.","categoria":"Cliente"}"#)
        let pipeline = ClassificationPipeline(store: store, settings: settings(), provider: fake)
        #expect(await pipeline.run(folder: "inbox") == 2)
        #expect(fake.calls == 1)
        #expect(try store.message(id: "r")?.tipo == "financeiro")
        #expect(try store.message(id: "r")?.justificativa == "Regra: é o banco")
        #expect(try store.message(id: "m")?.tipo == "pessoa")
        #expect(try store.rules().first?.hits == 1)
        #expect(await pipeline.run(folder: "inbox") == 0)
        #expect(await pipeline.lastError == nil)
    }

    @Test func pipelineRecordsErrorAndSkipsWithoutProvider() async throws {
        let store = try MailStore.inMemory()
        try store.upsert([sample(id: "x")])
        let broken = ClassificationPipeline(store: store, settings: settings(), provider: FakeProvider("nada"))
        #expect(await broken.run(folder: "inbox") == 0)
        #expect(await broken.lastError != nil)
        var s = AISettings()
        s.localEnabled = false
        let st = settings()
        try st.save(s)
        #expect(st.load() == s)
        let off = ClassificationPipeline(store: store, settings: st)
        #expect(await off.run(folder: "inbox") == 0)
        #expect(try store.unclassified(in: "inbox").count == 1)
    }
}
