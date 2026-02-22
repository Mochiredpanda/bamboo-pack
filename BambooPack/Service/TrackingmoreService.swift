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
                    
                    // Trackingmore returns an ARRAY inside data even for a single query.
                    // E.g.: {"meta":{...}, "data":[{"id":"...", ...}]}
                    // We need to rewrap it as a single object for our adapter: {"meta":{...}, "data":{"id":"...", ...}}
                    
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let meta = jsonObject["meta"] as? [String: Any],
                       let dataArray = jsonObject["data"] as? [[String: Any]],
                       let firstData = dataArray.first {
                        
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
            } catch {
                print("Failed to sync parcel \(number): \(error.localizedDescription)")
            }
        }
        
        return results
    }
}
