import Foundation

struct Track123Adapter: TrackingAPIAdapter {
    func adapt(data: Data, for parcel: Parcel) throws -> (NormalizedTrackingInfo, [TrackingTimelineEvent]) {
        let decoder = JSONDecoder()
        // Dates might need custom formatting, we'll parse manually.
        
        let trackObj = try decoder.decode(Track123TrackingObject.self, from: data)
        let trackingStatusString = trackObj.trackingStatus ?? "unknown"
        let status = mapStatus(from: trackObj.transitStatus ?? trackingStatusString)
        
        var events: [TrackingTimelineEvent] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        func parseDate(_ dateString: String) -> Date? {
            // Track123 dates are usually like "2024-01-01 12:00:00"
            return formatter.date(from: dateString)
        }
        
        if let localInfo = trackObj.localLogisticsInfo, let details = localInfo.trackingDetails {
            for detail in details {
                guard let tDate = detail.eventTime, let parsed = parseDate(tDate) else { continue }
                
                let event = TrackingTimelineEvent(
                    timestamp: parsed,
                    description: detail.eventDetail ?? "Update",
                    location: detail.address?.isEmpty == false ? detail.address : nil,
                    subStatus: detail.transitSubStatus
                )
                events.append(event)
            }
        }
        
        // Ensure events are sorted newest first
        events.sort { $0.timestamp > $1.timestamp }
        
        var latestDate: Date? = nil
        if let ltTime = trackObj.lastTrackingTime {
            latestDate = parseDate(ltTime)
        }
        
        let rawStr = String(data: data, encoding: .utf8)
        
        let normalizedInfo = NormalizedTrackingInfo(
            entryId: parcel.id ?? UUID(),
            providerTrackingId: trackObj.trackNo ?? trackObj.lastMileInfo?.lmTrackNo,
            status: status,
            transitTime: trackObj.receiptDays,
            latestCheckpointTime: latestDate ?? events.first?.timestamp,
            rawPayload: rawStr
        )
        
        return (normalizedInfo, events)
    }
    
    // Maps Track123 statuses to native ParcelStatus
    private func mapStatus(from string: String) -> ParcelStatus {
        let lower = string.lowercased()
        
        // Primary string matching for `transitStatus` (PENDING, MIGHT BE "INFO_RECEIVED", "IN_TRANSIT")
        if lower.contains("pending") || lower.contains("info_received") {
            return .preShipment
        } else if lower.contains("transit") || lower.contains("pickup") || lower.contains("departed") {
            return .inTransit
        } else if lower.contains("out_for_delivery") || lower.contains("outfordelivery") {
            return .outForDelivery
        } else if lower.contains("delivered") || lower.contains("receive") {
            return .delivered
        } else if lower.contains("exception") || lower.contains("alert") || lower.contains("undelivered") {
            return .exception
        } else if lower.contains("expired") {
            return .suspended
        }
        
        // Fallback for numbered `trackingStatus` strings
        switch string {
        case "001": return .preShipment // Pending
        case "002": return .inTransit   // In Transit
        case "003": return .outForDelivery
        case "004": return .delivered
        case "005": return .exception   // Alert / Exception
        case "006": return .suspended   // Expired
        default: return .inTransit      // Default assumption
        }
    }
}

// MARK: - Track123 Decoding Structures
struct Track123TrackingObject: Codable {
    let trackNo: String?
    let trackingStatus: String?
    let transitStatus: String?
    let receiptDays: Int?
    let lastTrackingTime: String?
    let localLogisticsInfo: Track123LogisticsInfo?
    let lastMileInfo: Track123LastMileInfo?
}

struct Track123LogisticsInfo: Codable {
    let trackingDetails: [Track123TrackingDetail]?
}

struct Track123LastMileInfo: Codable {
    let lmTrackNo: String?
}

struct Track123TrackingDetail: Codable {
    let address: String?
    let eventTime: String?
    let eventDetail: String?
    let transitSubStatus: String?
}
