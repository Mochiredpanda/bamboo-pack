import Foundation

struct TrackingmoreAdapter: TrackingAPIAdapter {
    func adapt(data: Data, for parcel: Parcel) throws -> (NormalizedTrackingInfo, [TrackingTimelineEvent]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Trackingmore largely uses ISO8601
        
        // Root parsing
        let root = try decoder.decode(TrackingmoreRootResponse.self, from: data)
        guard root.meta.code == 200, let bodyData = root.data else {
            throw TrackingAdapterError.invalidData
        }
        
        let providerTrackingId = bodyData.id
        
        // 1. Map Status
        let status = mapStatus(from: bodyData.delivery_status)
        
        // 2. Map Timeline Events
        var events: [TrackingTimelineEvent] = []
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let backupFormatter = ISO8601DateFormatter()
        
        func parseDate(_ dateString: String) -> Date? {
            return formatter.date(from: dateString) ?? backupFormatter.date(from: dateString)
        }
        
        // Helper to extract events from origin/destination
        func extractEvents(from trackinfo: [TrackingmoreCheckpoint]?) {
            guard let trackinfo = trackinfo else { return }
            for cp in trackinfo {
                guard let date = parseDate(cp.checkpoint_date) else { continue }
                
                // Construct location string
                var locationParts: [String] = []
                if let cit = cp.city, !cit.isEmpty { locationParts.append(cit) }
                if let st = cp.state, !st.isEmpty { locationParts.append(st) }
                if let co = cp.country_iso2, !co.isEmpty { locationParts.append(co) }
                let locationString = locationParts.joined(separator: ", ")
                
                let event = TrackingTimelineEvent(
                    timestamp: date,
                    description: cp.tracking_detail,
                    location: locationString.isEmpty ? nil : locationString,
                    subStatus: cp.checkpoint_delivery_substatus
                )
                events.append(event)
            }
        }
        
        // Merge origin and destination events
        extractEvents(from: bodyData.origin_info?.trackinfo)
        extractEvents(from: bodyData.destination_info?.trackinfo)
        
        // Sort newest first
        events.sort { $0.timestamp > $1.timestamp }
        
        // 3. Extract Latest Checkpoint Time
        let latestTime = parseDate(bodyData.latest_checkpoint_time ?? "") ?? events.first?.timestamp
        
        // 4. Extract Transit Time
        let transitTime = bodyData.transit_time
        
        // Preserve Raw Payload
        let rawPayload = String(data: data, encoding: .utf8)
        
        // Compile Normalized Tracking Info
        let info = NormalizedTrackingInfo(
            entryId: parcel.id ?? UUID(),
            providerTrackingId: providerTrackingId,
            status: status,
            transitTime: transitTime,
            latestCheckpointTime: latestTime,
            rawPayload: rawPayload
        )
        
        return (info, events)
    }
    
    /// Maps Trackingmore's string status ("pending", "notfound", "transit", "pickup", "delivered", "undelivered", "exception", "expired")
    /// to our global ParcelStatus.
    private func mapStatus(from trackingMoreStatus: String?) -> ParcelStatus {
        guard let statusStr = trackingMoreStatus?.lowercased() else { return .ordered }
        
        switch statusStr {
        case "pending", "notfound":
            return .preShipment
        case "transit":
            return .inTransit
        case "pickup", "outfordelivery":
            return .outForDelivery
        case "delivered":
            return .delivered
        case "undelivered", "exception", "expired":
            return .exception
        default:
            return .inTransit // Safe fallback
        }
    }
}

// MARK: - Trackingmore JSON Models

// Mirroring the Trackingmore API Response exactly as defined in documentation
private struct TrackingmoreRootResponse: Codable {
    let meta: TrackingmoreMeta
    let data: TrackingmoreData?
}

private struct TrackingmoreMeta: Codable {
    let code: Int
    let message: String?
}

private struct TrackingmoreData: Codable {
    let id: String?
    let tracking_number: String?
    let delivery_status: String?
    let substatus: String?
    let transit_time: Int?
    let latest_checkpoint_time: String?
    let origin_info: TrackingmoreInfoBlock?
    let destination_info: TrackingmoreInfoBlock?
}

private struct TrackingmoreInfoBlock: Codable {
    let trackinfo: [TrackingmoreCheckpoint]?
}

private struct TrackingmoreCheckpoint: Codable {
    let checkpoint_date: String
    let checkpoint_delivery_status: String?
    let checkpoint_delivery_substatus: String?
    let tracking_detail: String
    let location: String?
    let country_iso2: String?
    let state: String?
    let city: String?
}
