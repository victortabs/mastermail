import Foundation
@testable import MasterMailCore
import Testing

struct RichTextTests {
    @Test func boldShortcutBecomesIntentAndHTML() {
        var text = AttributedString("Olá **Victor**, tudo *bem*? Veja `x < y`.\n- item ")
        while RichText.applyMarkdownShortcuts(&text) {}
        #expect(String(text.characters) == "Olá Victor, tudo bem? Veja x < y.\n• item ")
        #expect(RichText.html(from: text) == "<div style=\"font-family:-apple-system,Helvetica,Arial,sans-serif;font-size:14px\">Olá <b>Victor</b>, tudo <i>bem</i>? Veja <code>x &lt; y</code>.<br>• item </div>")
    }

    @Test func nothingHappensWhileStillTyping() {
        var text = AttributedString("isso é **import")
        #expect(RichText.applyMarkdownShortcuts(&text) == false)
        var closed = AttributedString("isso é **importante**")
        #expect(RichText.applyMarkdownShortcuts(&closed) == false) // ainda sem espaço
        var underscore = AttributedString("arquivo_final_v2.pdf ")
        #expect(RichText.applyMarkdownShortcuts(&underscore) == false)
    }

    @Test func recipientParsing() {
        let list = Recipient.parseList("Marina <marina@bdil.com.br>, carlos@vhicom.com.br; ")
        #expect(list.map(\.emailAddress.address) == ["marina@bdil.com.br", "carlos@vhicom.com.br"])
        #expect(list[0].emailAddress.name == "Marina")
        #expect(list[0].display == "Marina <marina@bdil.com.br>")
        #expect(list[1].display == "carlos@vhicom.com.br")
    }
}
