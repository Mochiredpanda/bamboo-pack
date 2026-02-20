import SwiftUI

struct ParcelRowView: View {
    @ObservedObject var parcel: Parcel
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 1. DYNAMIC ICON
            // Visual cue for status & direction
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 42, height: 42) // Slightly larger touch target
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            // 2. MAIN INFO (Title & Carrier)
            VStack(alignment: .leading, spacing: 3) {
                Text(parcel.title ?? "Untitled Parcel")
                    .font(.body) // Standard readable size
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Carrier Tag
                    if let carrier = parcel.carrier, !carrier.isEmpty, carrier != "Auto" {
                        Text(carrier.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }
                    
                    // Fallback description if no carrier
                    if parcel.statusEnum == .ordered {
                        Text("Order Placed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 3. HERO STATUS (Right Side)
            // Prioritizes "Time" or "Action" over raw dates
            VStack(alignment: .trailing, spacing: 2) {
                if needsUpdate {
                    Text("Update Needed")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Tap to refresh")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if parcel.statusEnum == .delivered {
                    Text("Delivered")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    // Show relative time for delivered items (e.g. "Yesterday")
                    if let date = parcel.lastUpdated {
                        Text(date.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if parcel.statusEnum == .ordered {
                    // For ordered items, there is no delivery date yet
                    Text("Processing")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                } else {
                    // ACTIVE SHIPMENT logic
                    // If we had an 'estimatedDeliveryDate', we would calculate "In 3 Days"
                    // Since we only have lastUpdated in MVP, we show status clearly
                    Text(parcel.statusEnum.title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    // Shows the real ETA extracted from the tracking page
                    if let etaDate = parcel.estimatedDeliveryDate {
                        // Text("ETA: \(etaDate.formatted(date: .abbreviated, time: .omitted))")
                        Text("ETA: \(etaDate.formatted(.dateTime.month().day()))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Arriving Soon") 
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6) // Breathing room
    }
    
    // MARK: - Computed Properties for Logic
    
    var needsUpdate: Bool {
        // If there's no tracking history, it needs an update
        return parcel.trackingHistory == nil || parcel.trackingHistory?.isEmpty == true
    }
    
    var statusColor: Color {
        if needsUpdate { return .blue }
        switch parcel.statusEnum {
        case .delivered: return .green
        case .shipped: return .blue
        case .ordered: return .gray // Neutral for "not moving yet"
        case .exception: return .red // Important alert color
        default: return .blue
        }
    }
    
    var iconName: String {
        if needsUpdate { return "arrow.clockwise" }
        // Business Logic: Differentiate direction visual
        if parcel.directionEnum == .outgoing {
            return "arrow.up.cube" // Outgoing icon
        }
        
        switch parcel.statusEnum {
        case .delivered: return "checkmark" // Clear success indicator
        case .ordered: return "cart" // Shopping context
        case .shipped: return "truck.box" // Transit context
        default: return "cube"
        }
    }
}