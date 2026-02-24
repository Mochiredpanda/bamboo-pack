import Foundation

enum APIProvider: String, CaseIterable, Identifiable {
    case trackingmore = "Trackingmore"
    case track123 = "Track123"
    case aftership = "AfterShip"
    case seventeentrack = "17TRACK"
    
    var id: String { self.rawValue }
    
    // This value is used as the account key in the Keychain
    var keychainAccount: String {
        switch self {
        case .trackingmore: return "api_key_trackingmore"
        case .track123: return "api_key_track123"
        case .aftership: return "api_key_aftership"
        case .seventeentrack: return "api_key_17track"
        }
    }
}

protocol TrackingServiceProtocol {
    func syncActiveParcels(_ parcels: [Parcel]) async throws -> [(NormalizedTrackingInfo, [TrackingTimelineEvent])]
}
