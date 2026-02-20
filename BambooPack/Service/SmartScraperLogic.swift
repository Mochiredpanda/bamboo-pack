import Foundation

struct ScrapedStatus {
    let status: ParcelStatus
    let description: String?
    let expectedDelivery: Date?
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
        
        // 1. EXTRACT THE "NOISE"
        // If the text is massive, try to isolate the first 1000 characters
        // Carriers usually put the status at the top of the DOM.
        let searchArea = String(cleanText.prefix(1000))
        
        // 1.5 EXTRACT EXPECTED DELIVERY DATE
        var expectedDate: Date? = nil
        let dateTriggers = [
            "estimated delivery", 
            "expected delivery", 
            "estimated to arrive on or before", 
            "arriving by", 
            "delivery date"
        ]
        
        if dateTriggers.contains(where: searchArea.contains) {
            // Find the rough area around the trigger word
            if let trigger = dateTriggers.first(where: searchArea.contains),
               let range = searchArea.range(of: trigger) {
                // Look at the ~50 characters following the trigger word
                let targetArea = searchArea[range.upperBound...].prefix(100)
                
                // Use NSDataDetector to safely parse messy date formats (e.g. "Monday, Feb 23", "02/23/2026")
                if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                    let matches = detector.matches(in: String(targetArea), options: [], range: NSRange(location: 0, length: targetArea.count))
                    if let firstMatch = matches.first, let date = firstMatch.date {
                        expectedDate = date
                    }
                }
            }
        }
        
        // 2. DEFINE SEMANTIC BUCKETS
        // We look for signal words rather than exact sentences.
        let deliveredSignals = ["delivered", "left at", "signed for", "front desk", "porch", "mailbox"]
        let exceptionSignals = ["exception", "delay", "held", "customs", "action required", "delivery failed"]
        let transitSignals = ["transit", "way", "departed", "arrived at", "out for delivery", "we have your package", "possession", "picked up", "on vehicle"]
        let preShipmentSignals = ["label created", "information received", "awaiting item", "order processed"]
        
        // 3. HIERARCHICAL EVALUATION
        // Check highest priority (final states) first to avoid false positives 
        // if a page says "Label Created... Delivered" in its history table.
        
        // A. Delivered Check
        if deliveredSignals.contains(where: searchArea.contains) {
            // Find the specific trigger word for a better UI description
            let match = deliveredSignals.first(where: searchArea.contains) ?? "delivered"
            return ScrapedStatus(status: .delivered, description: match.capitalized, expectedDelivery: expectedDate)
        }
        
        // B. Exception Check
        if exceptionSignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .exception, description: "Attention Needed", expectedDelivery: expectedDate)
        }
        
        // C. Transit Check (Catches "We Have Your Package")
        if transitSignals.contains(where: searchArea.contains) {
            let match = transitSignals.first(where: searchArea.contains) ?? "in transit"
            
            // Refine description if it's specifically out for delivery
            if match == "out for delivery" || match == "on vehicle" {
                return ScrapedStatus(status: .outForDelivery, description: "Out for Delivery", expectedDelivery: expectedDate)
            }
            return ScrapedStatus(status: .inTransit, description: "In Transit", expectedDelivery: expectedDate)
        }
        
        // D. Pre-Shipment Check
        if preShipmentSignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .ordered, description: "Label Created", expectedDelivery: expectedDate)
        }
        
        // 4. FALLBACK: DYNAMIC EXTRACTION (The "Anchor" method)
        // If marketing teams use a completely new word, we try to find the standard "Status: XYZ" format.
        let statusPattern = /status\s*[:\-]?\s*([a-z\s]{3,20})/
        if let match = try? statusPattern.firstMatch(in: searchArea) {
            let captured = String(match.1).trimmingCharacters(in: .whitespaces)
            // Default to shipped if we find a status but don't recognize the words
            return ScrapedStatus(status: .shipped, description: captured.capitalized, expectedDelivery: expectedDate)
        }
        
        return nil
    }
}