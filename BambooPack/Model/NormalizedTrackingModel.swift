import Foundation

/// 2. Normalized Tracking Layer
/// Represents the core, unified shipping status parsed from any API provider
struct NormalizedTrackingInfo {
    /// Associated local Parcel UUID
    let entryId: UUID
    /// The unique ID assigned by the API provider
    let providerTrackingId: String?
    /// Standardized parcel status
    let status: ParcelStatus
    /// Number of days in transit
    let transitTime: Int?
    /// Date of the most recent tracking update
    let latestCheckpointTime: Date?
    /// The raw payload string for debugging or extensibility
    let rawPayload: String?
}

/// 3. Timeline Events Layer
/// A standardized structure representing a physical tracking scan/checkpoint
struct TrackingTimelineEvent: Codable, Identifiable {
    var id = UUID()
    let timestamp: Date
    let description: String
    let location: String?
    let subStatus: String?
}
