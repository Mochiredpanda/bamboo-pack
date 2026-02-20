import Foundation

struct ParsedParcelData {
    var trackingNumber: String?
    var orderNumber: String?
    var carrier: CarrierDetector.Carrier = .auto
}

struct SmartPasteParser {
    
    static func parse(text: String) -> ParsedParcelData {
        var result = ParsedParcelData()
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Extract Tracking Number (Strict RegEx)
        if let upsMatch = try? /\b1Z[0-9A-Z]{16}\b/.firstMatch(in: cleanText) {
            result.trackingNumber = String(upsMatch.0)
            result.carrier = .ups // Assuming you have .ups in your enum
        } 
        else if let uspsMatch = try? /\b(94|93|92|94|95)[0-9]{20}\b/.firstMatch(in: cleanText) {
            result.trackingNumber = String(uspsMatch.0)
            result.carrier = .usps
        }
        else if let fedexMatch = try? /\b[0-9]{12,15}\b/.firstMatch(in: cleanText) {
            // Note: 12-15 digits is a common FedEx format, but can have false positives
            result.trackingNumber = String(fedexMatch.0)
            result.carrier = .fedex
        }
        
        // 2. Extract Order Number (Heuristic RegEx)
        // Looks for "Order", "#", or "Order ID" followed by numbers/letters
        // e.g. "Order #12345-ABC" or "Order: 12345"
        let orderPattern = /(?i)(?:order\s*(?:number|id|#)?\s*[:#\-]?\s*)([A-Z0-9\-]{5,20})/
        
        if let orderMatch = try? orderPattern.firstMatch(in: cleanText) {
            result.orderNumber = String(orderMatch.1)
        }
        
        return result
    }
}
