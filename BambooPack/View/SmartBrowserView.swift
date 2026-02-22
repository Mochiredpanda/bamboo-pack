import SwiftUI
import WebKit
import Combine

// A ViewModel to bridge SwiftUI and WKWebView
class WebViewModel: ObservableObject {
    @Published var url: URL
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var title: String = ""
    
    // The actual WebView instance
    let webView: WKWebView
    
    init(url: URL) {
        self.url = url
        let config = WKWebViewConfiguration()
        // Let AutoresizingMask handle the frame
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
    }
    
    func load() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func reload() {
        webView.reload()
    }
}

struct SmartBrowserView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var model: WebViewModel
    let onScrape: (String) -> Void
    
    init(url: URL, onScrape: @escaping (String) -> Void) {
        self._model = StateObject(wrappedValue: WebViewModel(url: url))
        self.onScrape = onScrape
    }
    
    var body: some View {
        NavigationStack {
            WebViewWrapper(model: model, onScrape: onScrape)
                // Explicitly force the webview to fill the NavigationStack
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            // On macOS, dismiss() will close the secondary Window.
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        TextField("URL", text: .constant(model.url.absoluteString))
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 300, maxWidth: 500)
                            // Prevent editing but allow selecting and copying
                            .disabled(true)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 8) {
                            Button(action: { model.goBack() }) {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(!model.canGoBack)
                            .help("Go Back")
                            
                            Button(action: { model.goForward() }) {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(!model.canGoForward)
                            .help("Go Forward")
                            
                            Button(action: { model.reload() }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .help("Reload")
                            
                            Divider()
                                .frame(height: 16)
                            
                            Button(action: {
                                NSWorkspace.shared.open(model.url)
                            }) {
                                Image(systemName: "safari")
                            }
                            .help("Open in System Browser")
                        }
                    }
                }
                .navigationTitle(model.title.isEmpty ? "Browser" : model.title)
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear {
//            // Ensure model loads the CURRENT url, in case the view was recycled
//            if model.URL != URL {
//                model.URL = URL
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                model.load()
            }
        }
    }
}

// The Internal Representable
struct WebViewWrapper: NSViewRepresentable {
    @ObservedObject var model: WebViewModel
    let onScrape: (String) -> Void
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = model.webView
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.autoresizingMask = [.width, .height]
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No-op: Model manages state
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, model: model)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewWrapper
        var model: WebViewModel
        private var observers: [NSKeyValueObservation] = []
        
        init(parent: WebViewWrapper, model: WebViewModel) {
            self.parent = parent
            self.model = model
            super.init()
            
            // Setup KVO
            observers.append(model.webView.observe(\.canGoBack, options: .new) { [weak self] _, change in
                DispatchQueue.main.async { self?.model.canGoBack = change.newValue ?? false }
            })
            
            observers.append(model.webView.observe(\.canGoForward, options: .new) { [weak self] _, change in
                DispatchQueue.main.async { self?.model.canGoForward = change.newValue ?? false }
            })
            
            observers.append(model.webView.observe(\.isLoading, options: .new) { [weak self] _, change in
                DispatchQueue.main.async { self?.model.isLoading = change.newValue ?? false }
            })
            
            observers.append(model.webView.observe(\.title, options: .new) { [weak self] _, change in
                // change.newValue is String?? (Optional<Optional<String>>)
                // We flatten it to String
                let newTitle = (change.newValue ?? nil) ?? ""
                DispatchQueue.main.async { self?.model.title = newTitle }
            })
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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

extension Notification.Name {
    static let didScrapeTrackingData = Notification.Name("didScrapeTrackingData")
    static let closeSmartBrowser = Notification.Name("closeSmartBrowser")
}
