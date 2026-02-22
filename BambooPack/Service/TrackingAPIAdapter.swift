import Foundation

/// Defines the contract for an API-specific adapter to convert raw data 
/// into our internal `NormalizedTrackingInfo` format.
protocol TrackingAPIAdapter {
    func adapt(data: Data, for parcel: Parcel) throws -> (NormalizedTrackingInfo, [TrackingTimelineEvent])
}

enum TrackingAdapterError: Error {
    case invalidData
    case missingRequiredFields
    case decodingFailed(Error)
}
