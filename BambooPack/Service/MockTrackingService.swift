import Foundation

class MockTrackingService: TrackingService {
    
    func fetchTrackingInfo(carrier: String, trackingNumber: String) async throws -> TrackingInfo {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        let now = Date()
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        let events = [
            TrackingEvent(id: UUID(), timestamp: now, description: "Arrived at sorting facility", location: "Seattle, WA", status: .inTransit),
            TrackingEvent(id: UUID(), timestamp: oneDayAgo, description: "Departed from facility", location: "Portland, OR", status: .inTransit),
            TrackingEvent(id: UUID(), timestamp: twoDaysAgo, description: "Shipment information received", location: nil, status: .shipped)
        ]
        
        return TrackingInfo(
            trackingNumber: trackingNumber,
            carrier: carrier,
            status: .inTransit,
            estimatedDelivery: Calendar.current.date(byAdding: .day, value: 2, to: now),
            events: events
        )
    }
}
