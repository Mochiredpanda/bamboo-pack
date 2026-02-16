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

public enum ParcelStatus: Int, CaseIterable {
    case ordered = 0
    case shipped = 1
    case inTransit = 2
    case delivered = 3
    case exception = 4
    
    public var title: String {
        switch self {
        case .ordered: return "Ordered"
        case .shipped: return "Shipped"
        case .inTransit: return "In Transit"
        case .delivered: return "Delivered"
        case .exception: return "Exception"
        }
    }
    
    public var icon: String {
        switch self {
        case .ordered: return "cart"
        case .shipped: return "shippingbox"
        case .inTransit: return "truck.box"
        case .delivered: return "checkmark.circle.fill"
        case .exception: return "exclamationmark.triangle.fill"
        }
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
