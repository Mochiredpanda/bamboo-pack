import Foundation

struct ScrapedStatus {
    let status: ParcelStatus
    let description: String?
}

struct SmartScraperLogic {
    
    static func getTrackingURL(carrier: String, trackingNumber: String) -> URL? {
        let cleanCarrier = carrier.lowercased()
        let cleanTracking = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct Carrier URLs
        if cleanCarrier.contains("ups") { return URL(string: "https://www.ups.com/track?tracknum=\(cleanTracking)") }
        if cleanCarrier.contains("usps") { return URL(string: "https://tools.usps.com/go/TrackConfirmAction?tLabels=\(cleanTracking)") }
        if cleanCarrier.contains("fedex") { return URL(string: "https://www.fedex.com/fedextrack/?trknbr=\(cleanTracking)") }
        if cleanCarrier.contains("dhl") { return URL(string: "https://www.dhl.com/global-en/home/tracking/tracking-express.html?submit=1&tracking-id=\(cleanTracking)") }

        // Fallback Search Engine
        let encodedQuery = "\(carrier) tracking \(trackingNumber)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://duckduckgo.com/?q=\(encodedQuery)")
    }
    
    static func parseTrackingStatus(from text: String) -> ScrapedStatus? {
        let cleanText = text.lowercased()
        
        // ANCHOR STRATEGY: Look for the word "Status" followed by a few words.
        // regex: "status" or "status:", followed by up to 30 characters of a-z letters.
        let statusPattern = /status\s*[:\-]?\s*([a-z\s]{3,30})/
        
        if let match = try? statusPattern.firstMatch(in: cleanText) {
            let captured = String(match.1).trimmingCharacters(in: .whitespaces)
            
            if captured.contains("delivered") { return ScrapedStatus(status: .delivered, description: "Delivered") }
            if captured.contains("transit") || captured.contains("way") { return ScrapedStatus(status: .shipped, description: "In Transit") }
            if captured.contains("out for delivery") { return ScrapedStatus(status: .shipped, description: "Out for Delivery") }
            if captured.contains("exception") || captured.contains("delay") { return ScrapedStatus(status: .exception, description: "Exception/Delay") }
        }
        
        // STRICT EXACT PHRASE MATCHING (Fallback)
        // Must contain specific multi-word phrases that rarely appear in footers or ads.
        if cleanText.contains("out for delivery today") || cleanText.contains("loaded on delivery vehicle") {
            return ScrapedStatus(status: .shipped, description: "Out for Delivery")
        }
        
        if cleanText.contains("delivered, in/at mailbox") || cleanText.contains("delivered, front desk") {
            return ScrapedStatus(status: .delivered, description: "Delivered")
        }
        
        if cleanText.contains("shipping label created, usps awaiting item") {
            return ScrapedStatus(status: .ordered, description: "Label Created")
        }
        
        return nil
    }
}