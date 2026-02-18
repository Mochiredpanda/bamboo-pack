import Foundation

struct ScrapedStatus {
    let status: ParcelStatus
    let description: String?
}

struct SmartScraperLogic {
    
    /// Generates a "Safe Search" URL that usually leads to the tracking page
    /// This avoids hardcoding broken carrier URLs.
    static func getTrackingURL(carrier: String, trackingNumber: String) -> URL? {
        // Strategy: Use a search engine query which often shows a direct tracking card or link
        // e.g., "UPS tracking 1Z999..."
        let query = "\(carrier) tracking \(trackingNumber)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://duckduckgo.com/?q=\(encodedQuery)")
    }
    
    /// Parses the innerText of the webpage to find status keywords
    static func parseTrackingStatus(from text: String) -> ScrapedStatus? {
        let cleanText = text.lowercased()
        
        // 1. Direct Keyword Matching (Heuristic)
        if cleanText.contains("delivered") {
            return ScrapedStatus(status: .delivered, description: "Delivered")
        }
        if cleanText.contains("out for delivery") {
            return ScrapedStatus(status: .shipped, description: "Out for Delivery")
        }
        if cleanText.contains("in transit") || cleanText.contains("shipped") || cleanText.contains("on the way") {
            return ScrapedStatus(status: .shipped, description: "In Transit")
        }
        if cleanText.contains("label created") || cleanText.contains("shipment information received") {
            return ScrapedStatus(status: .ordered, description: "Label Created")
        }
        if cleanText.contains("exception") || cleanText.contains("delay") || cleanText.contains("held") {
            return ScrapedStatus(status: .exception, description: "Exception/Delay")
        }
        
        // 2. Regex Strategy (Contextual)
        // Look for "Status: [Something]"
        // This is harder to make generic across all sites without specific selectors,
        // but acts as a secondary layer if simple keywords fail or return false positives.
        
        return nil
    }
}
