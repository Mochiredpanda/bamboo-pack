import Foundation

// MARK: - Data Models

struct TrackingEvent: Codable, Identifiable {
    var id: UUID = UUID()
    let timestamp: Date
    let description: String
    let location: String?
    let status: ParcelStatus
    
    // Custom coding keys to handle external API mapping if needed
    enum CodingKeys: String, CodingKey {
        case timestamp, description, location, status
    }
}

struct TrackingInfo: Codable {
    let trackingNumber: String
    let carrier: String
    let status: ParcelStatus
    let estimatedDelivery: Date?
    let events: [TrackingEvent]
}

// MARK: - Protocol

protocol TrackingService {
    func fetchTrackingInfo(carrier: String, trackingNumber: String) async throws -> TrackingInfo
}

enum TrackingError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message): return "API Error: \(message)"
        case .notFound: return "Tracking number not found."
        }
    }
}
