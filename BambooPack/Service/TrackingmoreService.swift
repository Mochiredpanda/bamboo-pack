import Foundation

class TrackingmoreService {
    private let urlSession = URLSession.shared
    private let adapter = TrackingmoreAdapter()
    
    /// Requests updates for a batch of active tracking numbers
    func syncActiveParcels(_ parcels: [Parcel]) async throws -> [(NormalizedTrackingInfo, [TrackingTimelineEvent])] {
        guard !parcels.isEmpty else { return [] }
        
        let provider = APIProvider.trackingmore
        let keyString: String? = KeychainHelper.shared.read(service: "com.bamboopack.api", account: provider.keychainAccount)
        
        guard let apiKey = keyString, !apiKey.isEmpty else {
            throw TrackingError.apiError("Trackingmore API Key is missing. Please add it in Settings.")
        }
        
        // Build comma-separated string of tracking numbers
        let numbers = parcels.compactMap { $0.trackingNumber }.filter { !$0.isEmpty }
        guard !numbers.isEmpty else { return [] }
        
        let trackingNumbersString = numbers.joined(separator: ",")
        
        let decoder = JSONDecoder()
        
        // Trackingmore V4 GET endpoint batch fetches, but returns an array in `data`.
        // For our adapter which parses the Root Object `{meta:..., data:{id:...}}`,
        // it's easier to fetch individually if the batch size is small, or slightly mock the JSON to pass to the adapter.
        // Let's implement individual fetching for now to guarantee compatibility with our strict adapter.
        
        var results: [(NormalizedTrackingInfo, [TrackingTimelineEvent])] = []
        
        // To be safe against rate limits, we will do sequential querying for this demo.
        for parcel in parcels {
            guard let number = parcel.trackingNumber, !number.isEmpty else { continue }
            
            // Single GET request per parcel
            guard let singleUrl = URL(string: "https://api.trackingmore.com/v4/trackings/get?tracking_numbers=\(number)") else { continue }
            var singleRequest = URLRequest(url: singleUrl)
            singleRequest.httpMethod = "GET"
            singleRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            singleRequest.setValue(apiKey, forHTTPHeaderField: "Tracking-Api-Key")
            
            do {
                let (data, response) = try await urlSession.data(for: singleRequest)
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    
                    // Parse raw JSON to evaluate specific Trackingmore Meta codes
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let meta = jsonObject["meta"] as? [String: Any],
                       let code = meta["code"] as? Int {
                        
                        // Handle strict Trackingmore-specific Meta Codes
                        switch code {
                        case 200:
                            // Success
                            break
                        case 4011:
                            throw TrackingError.apiError("API Key is invalid or missing.")
                        case 4031:
                            throw TrackingError.apiError("Access Denied: Plan expired or query limit reached.")
                        case 4101:
                            throw TrackingError.apiError("Tracking number already exists (creation conflict).")
                        case 4102:
                            throw TrackingError.apiError("Tracking number does not exist.")
                        case 4103:
                            throw TrackingError.apiError("Exceeded maximum quantity (max 40 shipments per call).")
                        case 4110:
                            throw TrackingError.apiError("The tracking_number value is invalid.")
                        case 4291:
                            throw TrackingError.apiError("Rate limit exceeded. Try again later.")
                        case 5000:
                            throw TrackingError.apiError("Internal Server Error on TrackingMore's side.")
                        default:
                            if code != 200 {
                                let message = meta["message"] as? String ?? "Unknown Meta Code \(code)"
                                throw TrackingError.apiError("Trackingmore Error: \(message)")
                            }
                        }
                        
                        // Extract array safely for the adapter
                        if let dataArray = jsonObject["data"] as? [[String: Any]],
                           let firstData = dataArray.first {
                            
                            // To support additional tracking fields seamlessly, we can append them on Creation POST API calls.
                            // e.g., if we were doing a POST to /v4/trackings/create:
                            // "tracking_postal_code": parcel.recipientZipCode
                            // "destination_country": parcel.destinationCountryCode
                            // "customer_email": parcel.recipientEmail
                            
                            let rewrappedObj: [String: Any] = [
                                "meta": meta,
                                "data": firstData
                            ]
                            
                            if let rewrappedData = try? JSONSerialization.data(withJSONObject: rewrappedObj) {
                                let result = try adapter.adapt(data: rewrappedData, for: parcel)
                                results.append(result)
                            }
                        }
                    }
                }
            } catch {
                print("Failed to sync parcel \(number): \(error.localizedDescription)")
                // Optionally Rethrow if it's a critical auth error
                if let trackError = error as? TrackingError, case .apiError(let msg) = trackError, msg.contains("API Key is invalid") {
                    throw error
                }
            }
        }
        
        return results
    }
}
