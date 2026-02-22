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
        
        if cleanCarrier.contains("ups") { return URL(string: "https://www.ups.com/track?tracknum=\(cleanTracking)") }
        if cleanCarrier.contains("usps") { return URL(string: "https://tools.usps.com/go/TrackConfirmAction?tLabels=\(cleanTracking)") }
        if cleanCarrier.contains("fedex") { return URL(string: "https://www.fedex.com/fedextrack/?trknbr=\(cleanTracking)") }
        if cleanCarrier.contains("dhl") { return URL(string: "https://www.dhl.com/global-en/home/tracking/tracking-express.html?submit=1&tracking-id=\(cleanTracking)") }

        let encodedQuery = "\(carrier) tracking \(trackingNumber)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://duckduckgo.com/?q=\(encodedQuery)")
    }
    
    static func parseTrackingStatus(from text: String) -> ScrapedStatus? {
        let cleanText = text.lowercased()
        
        // 1. EXTRACT & NORMALIZE THE "NOISE"
        // CRITICAL FIX: Replace all newlines and multiple spaces with a single space.
        // This fixes the "Label\nCreated" bug.
        let rawPrefix = String(cleanText.prefix(1000))
        let searchArea = rawPrefix
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // 1.5 EXTRACT EXPECTED DELIVERY DATE
        var expectedDate: Date? = nil
        let dateTriggers = ["estimated delivery", "expected delivery", "arriving by", "delivery date", "deliver by"]
        
        if let trigger = dateTriggers.first(where: searchArea.contains),
           let range = searchArea.range(of: trigger) {
            let targetArea = searchArea[range.upperBound...].prefix(100)
            
            // Check for relative dates first
            if targetArea.contains("today") { expectedDate = Date() }
            else if targetArea.contains("tomorrow") { expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) }
            else {
                // Fallback to standard NSDataDetector
                if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                    let matches = detector.matches(in: String(targetArea), options: [], range: NSRange(location: 0, length: targetArea.count))
                    if let firstMatch = matches.first, let date = firstMatch.date {
                        expectedDate = date
                    }
                }
            }
        }
        
        // 2. DEFINE SEMANTIC BUCKETS (Expanded & Reordered)
        let deliveredSignals = ["delivered", "left at", "signed for", "front desk", "porch", "mailbox"]
        let pickupSignals = ["ready for pickup", "available for pickup", "awaiting collection", "pick up your package"]
        let exceptionSignals = ["exception", "delay", "held", "customs", "action required", "delivery failed", "returned to sender"]
        let outForDeliverySignals = ["out for delivery", "on vehicle", "loaded on delivery vehicle", "out for delivery today"]
        let transitSignals = ["transit", "way", "departed", "arrived at", "we have your package", "possession", "picked up", "processed at"]
        let preShipmentSignals = ["label created", "information received", "awaiting item", "order processed", "as soon as we get your package"]
        
        // 3. HIERARCHICAL EVALUATION (Strict Priority Order)
        
        if deliveredSignals.contains(where: searchArea.contains) {
            let match = deliveredSignals.first(where: searchArea.contains) ?? "delivered"
            return ScrapedStatus(status: .delivered, description: match.capitalized, expectedDelivery: expectedDate)
        }
        
        if pickupSignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .delivered, description: "Ready for Pickup", expectedDelivery: expectedDate) // Or map to a new .readyForPickup enum if you have one
        }
        
        if exceptionSignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .exception, description: "Attention Needed", expectedDelivery: expectedDate)
        }
        
        // MOVED UP: Must check Out For Delivery BEFORE general Transit
        if outForDeliverySignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .shipped, description: "Out for Delivery", expectedDelivery: expectedDate) 
            // Note: Use your specific Enum if you separated .shipped and .outForDelivery
        }
        
        if transitSignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .shipped, description: "In Transit", expectedDelivery: expectedDate)
        }
        
        if preShipmentSignals.contains(where: searchArea.contains) {
            return ScrapedStatus(status: .ordered, description: "Pre-Shipment", expectedDelivery: expectedDate)
        }
        
        // 4. FALLBACK: DYNAMIC EXTRACTION
        let statusPattern = /status\s*[:\-]?\s*([a-z\s]{3,20})/
        if let match = try? statusPattern.firstMatch(in: searchArea) {
            let captured = String(match.1).trimmingCharacters(in: .whitespaces)
            return ScrapedStatus(status: .shipped, description: captured.capitalized, expectedDelivery: expectedDate)
        }
        
        return nil
    }
}