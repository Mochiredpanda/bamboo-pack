import Foundation
import CoreData

extension Parcel {
    
    // MARK: - Enums
    
    public var statusEnum: ParcelStatus {
        get { return ParcelStatus(rawValue: Int(status)) ?? .ordered }
        set { status = Int16(newValue.rawValue) }
    }
    
    public var directionEnum: ParcelDirection {
        get { return ParcelDirection(rawValue: Int(direction)) ?? .incoming }
        set { direction = Int16(newValue.rawValue) }
    }
}

public enum ParcelStatus: Int, CaseIterable, Codable {
    case ordered = 0       // Pre-lifecycle (Incoming)
    case shipped = 1       // Legacy/Generic Shipped
    case inTransit = 2     // Active Lifecycle
    case delivered = 3     // Completed
    case exception = 4     // Issue
    
    // New Cases
    case draft = 5         // Pre-lifecycle (Outgoing)
    case preShipment = 6   // Active Lifecycle (Label Created)
    case outForDelivery = 7 // Active Lifecycle (Near End)
    case suspended = 8     // Tracking Removed (Archived/Frozen)
    
    public var title: String {
        switch self {
        case .ordered: return "Ordered"
        case .shipped: return "Shipped"
        case .inTransit: return "In Transit"
        case .delivered: return "Delivered"
        case .exception: return "Exception"
        case .draft: return "Draft"
        case .preShipment: return "Pre-Shipment"
        case .outForDelivery: return "Out for Delivery"
        case .suspended: return "Suspended"
        }
    }
    
    public var icon: String {
        switch self {
        case .ordered: return "cart"
        case .shipped: return "shippingbox"
        case .inTransit: return "truck.box"
        case .delivered: return "checkmark.circle.fill"
        case .exception: return "exclamationmark.triangle.fill"
        case .draft: return "doc.text"
        case .preShipment: return "envelope"
        case .outForDelivery: return "house"
        case .suspended: return "pause.circle"
        }
    }
    
    // Helper categories for UI Grouping
    public var category: StatusCategory {
        switch self {
        case .exception: return .exception
        case .ordered, .draft: return .toBeActivated
        case .delivered: return .delivered
        case .suspended: return .exception // Or separate? Let's put in exception for attention or separate
        default: return .onTheWay // shipped, inTransit, preShipment, outForDelivery
        }
    }
    
    public enum StatusCategory: String, CaseIterable {
        case exception = "Attention Needed"
        case toBeActivated = "To Be Activated"
        case onTheWay = "On The Way"
        case delivered = "Delivered"
    }
}

public enum ParcelDirection: Int, CaseIterable {
    case incoming = 0
    case outgoing = 1
    
    public var title: String {
        switch self {
        case .incoming: return "Incoming"
        case .outgoing: return "Outgoing"
        }
    }
}
