import Foundation

enum APIProvider: String, CaseIterable, Identifiable {
    case trackingmore = "Trackingmore"
    case aftership = "AfterShip"
    case seventeentrack = "17TRACK"
    
    var id: String { self.rawValue }
    
    // This value is used as the account key in the Keychain
    var keychainAccount: String {
        switch self {
        case .trackingmore: return "api_key_trackingmore"
        case .aftership: return "api_key_aftership"
        case .seventeentrack: return "api_key_17track"
        }
    }
}
