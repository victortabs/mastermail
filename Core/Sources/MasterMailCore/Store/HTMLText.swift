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
