import Foundation

/// Reduz HTML a texto puro para o Índice local. Não é um parser: basta para busca.
public enum HTMLText {
    public static func plainText(from html: String) -> String {
        var s = html
        // Remove blocos que nunca são conteúdo.
        for tag in ["script", "style", "head"] {
            s = s.replacing(try! Regex("(?is)<\(tag)\\b[^>]*>.*?</\(tag)>"), with: " ")
        }
        s = s.replacing(/(?i)<br\s*\/?>|<\/p>|<\/div>|<\/tr>|<\/li>|<\/h[1-6]>/, with: "\n")
        s = s.replacing(/<[^>]+>/, with: " ")
        s = decodeEntities(s)
        s = s.replacing(/[ \t\u{00A0}]+/, with: " ")
        s = s.replacing(/\s*\n\s*/, with: "\n")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Substitui `cid:xxx` pelos bytes do anexo inline, para assinaturas e imagens coladas aparecerem.
    public static func embedInline(_ html: String, attachments: [Attachment]) -> String {
        var out = html
        for a in attachments {
            guard let cid = a.contentId?.trimmingCharacters(in: CharacterSet(charactersIn: "<>")), !cid.isEmpty,
                  let bytes = a.contentBytes else { continue }
            let dataURL = "data:\(a.contentType ?? "image/png");base64,\(bytes)"
            out = out.replacingOccurrences(of: "cid:\(cid)", with: dataURL)
        }
        return out
    }

    /// Recolhe o histórico citado dentro da mensagem (a Conversa já mostra as anteriores). Sem JavaScript: usa <details>.
    public static func collapseQuotes(_ html: String) -> String {
        let markers: [Regex<Substring>] = [
            /<div[^>]*id="?divRplyFwdMsg"?/,            // Outlook
            /<div[^>]*class="?gmail_quote/,              // Gmail
            /<blockquote[^>]*type="?cite"?/,             // Apple Mail
            /<hr[^>]*>\s*(?:<[^>]+>\s*)*(?:De|From|Von|Da)\s*:/, // separador "De:" depois de uma linha
            /<div[^>]*class="?(?:moz-cite-prefix|OutlookMessageHeader)/,
        ]
        var cut: String.Index?
        for marker in markers {
            if let m = html.firstMatch(of: marker) {
                if cut == nil || m.range.lowerBound < cut! { cut = m.range.lowerBound }
            }
        }
        guard let cut, html.distance(from: html.startIndex, to: cut) > 20 else { return html }
        let head = String(html[..<cut])
        let tail = String(html[cut...])
        return head + "<details class=\"mm-quote\"><summary>··· citação</summary>" + tail + "</details>"
    }

    /// Sinais baratos de golpe (requisito Should): nome exibido com domínio diferente do endereço, link cujo texto é
    /// uma URL de outro domínio. Sem modelo.
    public static func phishingSignals(fromName: String, fromAddress: String, html: String?) -> [String] {
        var signals: [String] = []
        let addressDomain = fromAddress.split(separator: "@").last.map(String.init)?.lowercased() ?? ""
        if let m = fromName.firstMatch(of: /[\w.+-]+@([\w-]+\.[\w.-]+)/) {
            let nameDomain = String(m.output.1).lowercased()
            if !addressDomain.isEmpty, nameDomain != addressDomain { signals.append("O nome exibido mostra @\(nameDomain), mas o remetente real é @\(addressDomain).") }
        }
        if let html {
            for m in html.matches(of: /<a[^>]*href="(https?:\/\/[^"\/]+)[^"]*"[^>]*>\s*(https?:\/\/[^<\s]+)/) {
                let hrefHost = host(String(m.output.1))
                let textHost = host(String(m.output.2))
                if !hrefHost.isEmpty, !textHost.isEmpty, hrefHost != textHost, !hrefHost.hasSuffix("." + textHost), !textHost.hasSuffix("." + hrefHost) {
                    signals.append("Um link mostra \(textHost) mas leva para \(hrefHost).")
                    break
                }
            }
        }
        return signals
    }

    private static func host(_ url: String) -> String {
        (URL(string: url)?.host ?? "").lowercased().replacingOccurrences(of: "www.", with: "")
    }

    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
        "ccedil": "ç", "Ccedil": "Ç", "atilde": "ã", "Atilde": "Ã", "otilde": "õ", "Otilde": "Õ",
        "aacute": "á", "eacute": "é", "iacute": "í", "oacute": "ó", "uacute": "ú",
        "Aacute": "Á", "Eacute": "É", "Iacute": "Í", "Oacute": "Ó", "Uacute": "Ú",
        "acirc": "â", "ecirc": "ê", "ocirc": "ô", "Acirc": "Â", "Ecirc": "Ê", "Ocirc": "Ô",
        "agrave": "à", "Agrave": "À", "ndash": "–", "mdash": "—", "hellip": "…", "copy": "©", "reg": "®",
        "ldquo": "“", "rdquo": "”", "lsquo": "‘", "rsquo": "’",
    ]

    static func decodeEntities(_ s: String) -> String {
        s.replacing(/&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);/) { match in
            let body = String(match.output.1)
            if body.hasPrefix("#x"), let v = UInt32(body.dropFirst(2), radix: 16), let u = Unicode.Scalar(v) { return String(Character(u)) }
            if body.hasPrefix("#"), let v = UInt32(body.dropFirst(1)), let u = Unicode.Scalar(v) { return String(Character(u)) }
            return named[body] ?? String(match.output.0)
        }
    }
}
