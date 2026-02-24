import Foundation
import CoreData

class TrackingmoreService: TrackingServiceProtocol {
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
                if let httpResponse = response as? HTTPURLResponse {
                    
                    // Parse raw JSON to evaluate specific Trackingmore Meta codes
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let meta = jsonObject["meta"] as? [String: Any],
                       let code = meta["code"] as? Int {
                        
                        var dataIsProcessed = false
                        
                        // Handle strict Trackingmore-specific Meta Codes
                        switch code {
                        case 200:
                            // Success
                            break
                        case 4011:
                            throw TrackingError.apiError("API Key is invalid or missing.")
                        case 4031:
                            throw TrackingError.apiError("Access Denied: Plan expired or query limit reached.")
                        case 4190:
                            throw TrackingError.apiError("You are reaching the maximum quota limitation, please upgrade your current plan.")
                        case 4101:
                            throw TrackingError.apiError("Tracking number already exists (creation conflict).")
                        case 4102:
                            // Try creating it on the fly
                            let created = try await createTracking(for: parcel, apiKey: apiKey)
                            if created {
                                // Retry GET
                                let (retryData, retryResponse) = try await urlSession.data(for: singleRequest)
                                if let retryHttp = retryResponse as? HTTPURLResponse, (200...299).contains(retryHttp.statusCode),
                                   let retryJson = try? JSONSerialization.jsonObject(with: retryData) as? [String: Any],
                                   let retryMeta = retryJson["meta"] as? [String: Any],
                                   let retryCode = retryMeta["code"] as? Int, retryCode == 200,
                                   let retryDataArray = retryJson["data"] as? [[String: Any]],
                                   let retryFirstData = retryDataArray.first {
                                    
                                    let rewrappedObj: [String: Any] = [
                                        "meta": retryMeta,
                                        "data": retryFirstData
                                    ]
                                    if let rewrappedData = try? JSONSerialization.data(withJSONObject: rewrappedObj) {
                                        let result = try adapter.adapt(data: rewrappedData, for: parcel)
                                        results.append(result)
                                    }
                                }
                            } else {
                                throw TrackingError.apiError("Failed to create tracking number automatically.")
                            }
                            // Important: Skip extracting the array since the first try was a 4102 error
                            dataIsProcessed = true
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
                        
                        // Extract array safely for the adapter if not already processed via creation fallback
                        if !dataIsProcessed {
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
                }
            } catch {
                print("Failed to sync parcel \(number): \(error.localizedDescription)")
                // Optionally Rethrow if it's a critical auth error
                if let trackError = error as? TrackingError, case .apiError(let msg) = trackError {
                    if msg.contains("API Key is invalid") || msg.contains("quota limitation") || msg.contains("Plan expired") {
                        throw error
                    }
                }
            }
        }
        
        return results
    }
    
    // MARK: - Tracking Creation
    /// Internal helper to register a new tracking number on Trackingmore if it doesn't exist
    private func createTracking(for parcel: Parcel, apiKey: String) async throws -> Bool {
        guard let url = URL(string: "https://api.trackingmore.com/v4/trackings/create"),
              let trackingNumber = parcel.trackingNumber, !trackingNumber.isEmpty else {
            return false
        }
        
        var resolvedCourierCode = parcel.carrier?.lowercased()
        
        // Auto-detect courier if none provided or set to "auto"
        if resolvedCourierCode == nil || resolvedCourierCode == "auto" || resolvedCourierCode!.isEmpty {
            if let detectUrl = URL(string: "https://api.trackingmore.com/v4/couriers/detect") {
                var detectReq = URLRequest(url: detectUrl)
                detectReq.httpMethod = "POST"
                detectReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                detectReq.setValue(apiKey, forHTTPHeaderField: "Tracking-Api-Key")
                let detectPayload: [String: Any] = ["tracking_number": trackingNumber]
                detectReq.httpBody = try? JSONSerialization.data(withJSONObject: detectPayload)
                
                if let (detectData, _) = try? await urlSession.data(for: detectReq),
                   let detectJson = try? JSONSerialization.jsonObject(with: detectData) as? [String: Any],
                   let dMeta = detectJson["meta"] as? [String: Any],
                   let dCode = dMeta["code"] as? Int, dCode == 200,
                   let dataArray = detectJson["data"] as? [[String: Any]],
                   let firstMatch = dataArray.first,
                   let autoCourier = firstMatch["courier_code"] as? String {
                    resolvedCourierCode = autoCourier
                }
            }
        }
        
        guard let finalCourier = resolvedCourierCode, !finalCourier.isEmpty else {
            // Cannot create without a courier code
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Tracking-Api-Key")
        
        // Trackingmore V4 payload needs tracking_number at minimum
        // We inject order_number if present
        var payload: [String: Any] = [
            "tracking_number": trackingNumber,
            "courier_code": finalCourier
        ]
        
        if let orderNumber = parcel.orderNumber, !orderNumber.isEmpty {
            payload["order_number"] = orderNumber
        }
        
        if let title = parcel.title, !title.isEmpty {
            payload["title"] = title
        }
        
        // Note: we omit `courier_code` to allow Auto-Detect. If we pass strictly "FedEx" and trackingmore expects "fedex", it yields an error.
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await urlSession.data(for: request)
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Create Tracking Response for \(trackingNumber): \(jsonObject)")
        } else {
            print("Create Tracking Raw Response: \(String(data: data, encoding: .utf8) ?? "unknown")")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return false
        }
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let meta = jsonObject["meta"] as? [String: Any],
           let code = meta["code"] as? Int {
            if code == 4190 {
                throw TrackingError.apiError("You are reaching the maximum quota limitation, please upgrade your current plan.")
            }
            if code == 4031 {
                throw TrackingError.apiError("Access Denied: Plan expired or query limit reached.")
            }
            return code == 200
        }
        
        return false
    }
    
    // MARK: - Validation
    static func validateKey(apiKey: String) async throws {
        guard !apiKey.isEmpty else {
            throw TrackingError.apiError("API Key is empty.")
        }
        
        guard let url = URL(string: "https://api.trackingmore.com/v4/couriers/all") else {
            throw TrackingError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Tracking-Api-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw TrackingError.networkError(NSError(domain: "Network Error", code: 0))
        }
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let meta = jsonObject["meta"] as? [String: Any],
           let code = meta["code"] as? Int {
            
            switch code {
            case 200:
                return // Valid
            case 4011:
                throw TrackingError.apiError("API Key is invalid or missing.")
            case 4031:
                throw TrackingError.apiError("Access Denied: Plan expired or query limit reached.")
            case 4291:
                throw TrackingError.apiError("Rate limit exceeded. Try again later.")
            default:
                if code != 200 {
                    let message = meta["message"] as? String ?? "Unknown Meta Code \(code)"
                    throw TrackingError.apiError(message)
                }
            }
        } else {
             throw TrackingError.apiError("Invalid response format.")
        }
    }
}
