import SwiftUI

struct ParcelRowView: View {
    @ObservedObject var parcel: Parcel
    
    var body: some View {
        HStack {
            Image(systemName: parcel.statusEnum.icon)
                .font(.title2)
                .foregroundColor(parcel.statusEnum == .delivered ? .green : .redPandaRust)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(parcel.title ?? "Untitled Parcel")
                    .font(.headline)
                
                HStack {
                    if let carrier = parcel.carrier, !carrier.isEmpty {
                        Text(carrier)
                            .font(.caption)
                            .padding(4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text(parcel.trackingNumber ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(parcel.statusEnum.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastUpdated = parcel.lastUpdated {
                    Text(lastUpdated, style: .date)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
