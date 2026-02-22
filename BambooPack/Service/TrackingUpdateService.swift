import Foundation
import Combine

class TrackingUpdateService: ObservableObject {
    static let shared = TrackingUpdateService()
    
    // Using PassthroughSubject from Combine for strong typing
    let didScrapeData = PassthroughSubject<(url: URL, text: String), Never>()
    let closeSmartBrowser = PassthroughSubject<URL, Never>()
    
    private init() {}
}
