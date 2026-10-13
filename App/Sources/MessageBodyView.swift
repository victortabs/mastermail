import MasterMailCore
import SwiftUI
import WebKit

/// Mostra o corpo da mensagem num WKWebView isolado. Imagens remotas e scripts bloqueados por padrão (requisito Must).
struct MessageBodyView: NSViewRepresentable {
    let body: ItemBody

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.setValue(false, forKey: "drawsBackground")
        Task { await Self.applyBlockList(to: config.userContentController) }
        return web
    }

    func updateNSView(_ web: WKWebView, context: Context) {
        guard context.coordinator.lastLoaded != body else { return }
        context.coordinator.lastLoaded = body
        let html = body.contentType.lowercased() == "html"
            ? body.content
            : "<pre style=\"white-space:pre-wrap;font-family:-apple-system\">\(body.content.htmlEscaped)</pre>"
        web.loadHTMLString(Self.wrap(html), baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoaded: ItemBody?

        /// Links abrem no navegador do sistema, nunca dentro da mensagem.
        func webView(_: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            if action.navigationType == .linkActivated, let url = action.request.url {
                NSWorkspace.shared.open(url)
                return .cancel
            }
            return .allow
        }
    }

    private static func wrap(_ html: String) -> String {
        """
        <!doctype html><meta charset="utf-8">
        <style>body{font:14px -apple-system,sans-serif;color:CanvasText;background:transparent;margin:0}
        @media (prefers-color-scheme: dark){body{color:#ddd}} img{max-width:100%}</style>
        \(html)
        """
    }

    /// Bloqueia todo carregamento http(s): imagens de rastreio, fontes, scripts. `cid:` e `data:` passam.
    private static let blockList = #"[{"trigger":{"url-filter":"^https?://"},"action":{"type":"block"}}]"#

    private static func applyBlockList(to controller: WKUserContentController) async {
        if let list = try? await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "block-remote", encodedContentRuleList: blockList) {
            controller.add(list)
        }
    }
}

private extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
