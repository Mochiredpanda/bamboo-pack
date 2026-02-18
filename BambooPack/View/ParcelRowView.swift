import SwiftUI

struct ParcelRowView: View {
    @ObservedObject var parcel: Parcel
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Status Icon with background
            ZStack {
                Circle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 36, height: 36)
                
                Image(systemName: parcel.statusEnum.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(parcel.statusEnum == .delivered ? .green : .blue)
            }
            // Removed fixed frame to allow flexible layout if needed, but Circle handles it.
            
            VStack(alignment: .leading, spacing: 4) {
                Text(parcel.title ?? "Untitled Parcel")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 6) {
                    if let carrier = parcel.carrier, !carrier.isEmpty {
                        Text(carrier.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }
                    
                    if let tracking = parcel.trackingNumber, !tracking.isEmpty {
                        Text(tracking)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let order = parcel.orderNumber, !order.isEmpty {
                        Text(order)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // Status Text
                Text(parcel.statusEnum.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(parcel.statusEnum == .delivered ? .green : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(parcel.statusEnum == .delivered ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    )
                
                if let lastUpdated = parcel.lastUpdated {
                    Text(lastUpdated, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 8)
    }
}
