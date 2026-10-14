import MasterMailCore
import SwiftUI
import WebKit

/// Mostra o corpo da mensagem num WKWebView isolado. Imagens remotas e scripts bloqueados por padrão (requisito Must).
struct MessageBodyView: NSViewRepresentable {
    let html: String?
    let text: String
    /// Usuário pediu para carregar imagens remotas desta mensagem.
    var allowRemote = false
    /// Altura do conteúdo, medida depois de carregar, para a mensagem caber num ScrollView.
    @Binding var height: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let web = PassthroughWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        context.coordinator.onHeight = { h in Task { @MainActor in height = max(40, h) } }
        web.onClick = { [weak web, weak coordinator = context.coordinator] in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                guard let web else { return }
                coordinator?.webView(web, didFinish: nil)
            }
        }
        web.setValue(false, forKey: "drawsBackground")
        return web
    }

    func updateNSView(_ web: WKWebView, context: Context) {
        let content = html.map(HTMLText.collapseQuotes) ?? "<pre style=\"white-space:pre-wrap;font-family:-apple-system\">\(text.htmlEscaped)</pre>"
        guard context.coordinator.lastLoaded != content else { return }
        context.coordinator.lastLoaded = content
        web.loadHTMLString(HTMLText.document(content, allowRemoteImages: allowRemote), baseURL: nil)
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

        /// Clique em "··· citação": o conteúdo cresce, mede de novo.
        func webView(_ web: WKWebView, didCommit _: WKNavigation!) {}
        func webView(_ web: WKWebView, decidePolicyFor action: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
            if action.navigationType == .linkActivated, let url = action.request.url {
                if ["https", "http", "mailto"].contains(url.scheme?.lowercased() ?? "") { NSWorkspace.shared.open(url) }
                return (.cancel, preferences)
            }
            return (action.request.url?.scheme == "about" ? .allow : .cancel, preferences)
        }

    }


}

/// A mensagem cabe inteira (altura medida), então a roda do mouse vai para o ScrollView de fora.
final class PassthroughWebView: WKWebView {
    var onClick: (() -> Void)?

    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        onClick?()
    }
}

private extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
