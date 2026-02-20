import Foundation
import WebKit
import Combine

class BackgroundScraper: NSObject, ObservableObject, WKNavigationDelegate {
    static let shared = BackgroundScraper()
    
    // We keep a strong reference so it is not deallocated when the view goes away
    private var webView: WKWebView!
    private var completion: ((String?) -> Void)?
    private var timeoutItem: DispatchWorkItem?
    
    override private init() {
        super.init()
        let config = WKWebViewConfiguration()
        // The frame MUST be non-zero to convince WebKit to properly render the DOM
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
        self.webView.navigationDelegate = self
    }
    
    func scrape(url: URL, completion: @escaping (String?) -> Void) {
        // Cancel any pending tasks
        timeoutItem?.cancel()
        self.webView.stopLoading()
        
        self.completion = completion
        
        // Setup safety timeout in case the navigation fails or hangs (e.g., CAPTCHA)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.webView.stopLoading()
            self.completion?(nil) // Nil indicates failure/timeout
        }
        self.timeoutItem = workItem
        
        // 7 seconds is generous enough for slow connections but fast enough
        // so the user knows they need to fallback to the manual sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0, execute: workItem)
        
        self.webView.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // We wait a moment after the initial load so javascript can dynamically render tracking tables
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            
            self.webView.evaluateJavaScript("document.body.innerText") { result, _ in
                // Only fire completion if the timeout hasn't already cancelled this request
                if let workItem = self.timeoutItem, !workItem.isCancelled {
                    workItem.cancel()
                    self.completion?(result as? String)
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let workItem = self.timeoutItem, !workItem.isCancelled {
            workItem.cancel()
            self.completion?(nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let workItem = self.timeoutItem, !workItem.isCancelled {
            workItem.cancel()
            self.completion?(nil)
        }
    }
}
