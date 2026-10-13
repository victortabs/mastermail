import Foundation

/// Editor rich text com atalhos de Markdown (requisito): o usuário digita `**x**` e vira negrito na hora.
/// Formatação guardada como `inlinePresentationIntent`; a saída para e-mail é HTML.
public enum RichText {
    /// Aplica os atalhos encontrados no texto. Devolve true se mudou algo.
    @discardableResult
    public static func applyMarkdownShortcuts(_ text: inout AttributedString) -> Bool {
        let plain = String(text.characters)
        // Só dispara quando o usuário acabou de digitar espaço ou Enter: nada de converter no meio da palavra.
        guard let last = plain.last, last.isWhitespace else { return false }
        // Sem lookbehind no Regex do Swift: captura o vizinho e usa só o miolo (output.2).
        let patterns: [(Regex<(Substring, Substring, Substring)>, Int, InlinePresentationIntent)] = [
            (/(^|[^*])\*\*([^*\n]+?)\*\*/, 2, .stronglyEmphasized),
            (/(^|[^\w*])\*([^*\n]+?)\*/, 1, .emphasized),
            (/(^|[^`])`([^`\n]+?)`/, 1, .code),
        ]
        for (regex, marker, intent) in patterns {
            guard let match = plain.firstMatch(of: regex) else { continue }
            let inner = match.output.2
            // O caractere seguinte ao fechamento não pode ser letra (evita snake_case).
            if marker == 1, inner.endIndex < plain.endIndex {
                let close = plain.index(inner.endIndex, offsetBy: 1)
                if close < plain.endIndex, plain[close].isLetter || plain[close].isNumber { continue }
            }
            let lower = plain.index(inner.startIndex, offsetBy: -marker)
            let upper = plain.index(inner.endIndex, offsetBy: marker)
            let start = text.index(text.startIndex, offsetByCharacters: plain.distance(from: plain.startIndex, to: lower))
            let end = text.index(start, offsetByCharacters: plain.distance(from: lower, to: upper))
            var replacement = AttributedString(String(inner))
            replacement.inlinePresentationIntent = intent
            text.replaceSubrange(start..<end, with: replacement)
            return true
        }
        // "- " no começo da linha vira marcador de lista.
        if let match = plain.firstMatch(of: /(?m)^- /) {
            let start = text.index(text.startIndex, offsetByCharacters: plain.distance(from: plain.startIndex, to: match.range.lowerBound))
            let end = text.index(start, offsetByCharacters: 2)
            text.replaceSubrange(start..<end, with: AttributedString("• "))
            return true
        }
        return false
    }

    /// HTML para o corpo do e-mail. Parágrafos por linha; negrito, itálico e código pelos intents.
    public static func html(from text: AttributedString) -> String {
        var out = ""
        for run in text.runs {
            var piece = String(text[run.range].characters).htmlEscaped.replacingOccurrences(of: "\n", with: "<br>")
            let intent = run.inlinePresentationIntent ?? []
            if intent.contains(.code) { piece = "<code>\(piece)</code>" }
            if intent.contains(.emphasized) { piece = "<i>\(piece)</i>" }
            if intent.contains(.stronglyEmphasized) { piece = "<b>\(piece)</b>" }
            out += piece
        }
        return "<div style=\"font-family:-apple-system,Helvetica,Arial,sans-serif;font-size:14px\">\(out)</div>"
    }
}

extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
