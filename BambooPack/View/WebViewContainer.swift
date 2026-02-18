import SwiftUI
import WebKit

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#else
typealias ViewRepresentable = UIViewRepresentable
#endif

struct WebViewContainer: ViewRepresentable {
    let url: URL
    let onScrape: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        return createWebView(context: context)
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        loadRequest(in: nsView)
    }
    #else
    func makeUIView(context: Context) -> WKWebView {
        return createWebView(context: context)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadRequest(in: uiView)
    }
    #endif
    
    private func createWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        #if os(macOS)
        webView.autoresizingMask = [.width, .height]
        #endif
        
        return webView
    }
    
    private func loadRequest(in webView: WKWebView) {
        if let currentURL = webView.url, currentURL == url {
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        
        init(parent: WebViewContainer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Wait a brief moment for dynamic content (JS frameworks) to render
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                webView.evaluateJavaScript("document.body.innerText") { result, error in
                    if let text = result as? String {
                        self.parent.onScrape(text)
                    }
                }
            }
        }
    }
}
