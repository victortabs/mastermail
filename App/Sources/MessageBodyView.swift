import MasterMailCore
import SwiftUI
import WebKit

/// Mostra o corpo da mensagem num WKWebView isolado. Imagens remotas e scripts bloqueados por padrão (requisito Must).
struct MessageBodyView: NSViewRepresentable {
    let html: String?
    let text: String
    /// Altura do conteúdo, medida depois de carregar, para a mensagem caber num ScrollView.
    @Binding var height: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        context.coordinator.onHeight = { h in Task { @MainActor in height = max(40, h) } }
        web.setValue(false, forKey: "drawsBackground")
        Task { await Self.applyBlockList(to: config.userContentController) }
        return web
    }

    func updateNSView(_ web: WKWebView, context: Context) {
        let content = html ?? "<pre style=\"white-space:pre-wrap;font-family:-apple-system\">\(text.htmlEscaped)</pre>"
        guard context.coordinator.lastLoaded != content else { return }
        context.coordinator.lastLoaded = content
        web.loadHTMLString(Self.wrap(content), baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoaded: String?
        var onHeight: ((CGFloat) -> Void)?

        func webView(_ web: WKWebView, didFinish _: WKNavigation!) {
            web.evaluateJavaScript("document.documentElement.scrollHeight") { [onHeight] value, _ in
                if let h = value as? Double { onHeight?(CGFloat(h) + 8) }
            }
        }

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
