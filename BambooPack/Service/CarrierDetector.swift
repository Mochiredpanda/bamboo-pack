import Foundation

struct CarrierDetector {
    
    public enum Carrier: String, CaseIterable, Identifiable {
        case auto = "Auto-Detect"
        case ups = "UPS"
        case fedex = "FedEx"
        case usps = "USPS"
        case dhl = "DHL"
        case unknown = "Other"
        
        public var id: String { rawValue }
        public var name: String { rawValue }
    }
    
    static func detect(trackingNumber: String) -> Carrier {
        let cleanNumber = trackingNumber.replacingOccurrences(of: " ", with: "").uppercased()
        
        // UPS: 1Z... (18 alphanumeric)
        if cleanNumber.hasPrefix("1Z") && cleanNumber.count == 18 {
            return .ups
        }
        
        // FedEx: 12-14 digits usually, sometimes 96...
        // Common ground: 12 digits, 15 digits, 20 digits, 22 digits
        // Simple heuristic for now: pure digits, length check
        if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleanNumber)) {
            let length = cleanNumber.count
            if (12...15).contains(length) || length == 22 || length == 34 {
                 // Weak check, but FedEx is common for these lengths
                 return .fedex
            }
            
            // USPS: 20-22 digits (e.g. 9400...)
            if (20...22).contains(length) && cleanNumber.hasPrefix("9") {
                return .usps
            }
        }
        
        // DHL: 10 digit numeric
        if cleanNumber.count == 10 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleanNumber)) {
            return .dhl
        }

        return .unknown
    }
}
