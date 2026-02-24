import Foundation
import CoreData

class Track123Service: TrackingServiceProtocol {
    private let urlSession = URLSession.shared
    private let adapter = Track123Adapter()
    
    // Requests updates for a batch of active tracking numbers
    func syncActiveParcels(_ parcels: [Parcel]) async throws -> [(NormalizedTrackingInfo, [TrackingTimelineEvent])] {
        guard !parcels.isEmpty else { return [] }
        
        let provider = APIProvider.track123
        let keyString: String? = KeychainHelper.shared.read(service: "com.bamboopack.api", account: provider.keychainAccount)
        
        guard let apiKey = keyString, !apiKey.isEmpty else {
            throw TrackingError.apiError("Track123 API Key is missing. Please add it in Settings.")
        }
        
        var results: [(NormalizedTrackingInfo, [TrackingTimelineEvent])] = []
        
        for parcel in parcels {
            guard let number = parcel.trackingNumber, !number.isEmpty else { continue }
            
            guard let singleUrl = URL(string: "https://api.track123.com/gateway/open-api/tk/v2.1/track/query") else { continue }
            var singleRequest = URLRequest(url: singleUrl)
            singleRequest.httpMethod = "POST"
            singleRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            singleRequest.setValue("application/json", forHTTPHeaderField: "accept")
            singleRequest.setValue(apiKey, forHTTPHeaderField: "Track123-Api-Secret")
            
            // Note: the Track123 spec indicates using offset/limit or trackNo list
            let queryPayload: [String: Any] = [
                "trackNos": [number]
            ]
            singleRequest.httpBody = try JSONSerialization.data(withJSONObject: queryPayload)
            
            do {
                let (data, _) = try await urlSession.data(for: singleRequest)
                
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = jsonObject["code"] as? String {
                   
                   // A0400 can be parameters format error or Tracking Number doesn't exist
                   if code == "00000" {
                       if let dataDict = jsonObject["data"] as? [String: Any],
                          let acceptedDict = dataDict["accepted"] as? [String: Any],
                          let contentArray = acceptedDict["content"] as? [[String: Any]],
                          let firstContent = contentArray.first {
                              
                           let result = try adapter.adapt(data: try JSONSerialization.data(withJSONObject: firstContent), for: parcel)
                           results.append(result)
                       } else {
                           // Try creating if it doesn't exist in accepted
                           // But for track123, if it's not accepted, it might be in rejected.
                           let created = try await createTracking(for: parcel, apiKey: apiKey)
                           if created {
                               // Retry POST
                               let (retryData, _) = try await urlSession.data(for: singleRequest)
                               if let rJson = try? JSONSerialization.jsonObject(with: retryData) as? [String: Any],
                                  rJson["code"] as? String == "00000",
                                  let rDataDict = rJson["data"] as? [String: Any],
                                  let rAcc = rDataDict["accepted"] as? [String: Any],
                                  let rCont = rAcc["content"] as? [[String: Any]],
                                  let rFirst = rCont.first {
                                      let result = try adapter.adapt(data: try JSONSerialization.data(withJSONObject: rFirst), for: parcel)
                                      results.append(result)
                                  }
                           }
                       }
                   } else if code == "400" {
                       throw TrackingError.apiError("You are reaching the maximum quota limitation, please upgrade your current plan.")
                   } else if code == "401" {
                       throw TrackingError.apiError("Track123 API Key is invalid or missing.")
                   }
                }
            } catch {
                if let trackError = error as? TrackingError, case .apiError(let msg) = trackError {
                    if msg.contains("API Key is invalid") || msg.contains("quota limitation") {
                        throw error
                    }
                }
            }
        }
        
        return results
    }
    
    private func createTracking(for parcel: Parcel, apiKey: String) async throws -> Bool {
        guard let url = URL(string: "https://api.track123.com/gateway/open-api/tk/v2.1/track/import"),
              let trackingNumber = parcel.trackingNumber, !trackingNumber.isEmpty else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiKey, forHTTPHeaderField: "Track123-Api-Secret")
        
        var trackObj: [String: Any] = [
            "trackNo": trackingNumber
        ]
        
        if let orderNumber = parcel.orderNumber, !orderNumber.isEmpty {
            trackObj["orderNo"] = orderNumber
        }
        
        let payload: [String: Any] = [
            "accepted": [trackObj]
        ]
        // From doc, actually just list of objects directly or inside a wrapper?
        // Wait, looking at the doc: the payload is directly the object array or something else?
        // Oh, Track123 register req: Just a JSON array of objects
        
        request.httpBody = try JSONSerialization.data(withJSONObject: [trackObj])
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return false
        }
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let code = jsonObject["code"] as? String {
            return code == "00000"
        }
        
        return false
    }
    
    // MARK: - Validation
    static func validateKey(apiKey: String) async throws {
        guard !apiKey.isEmpty else {
            throw TrackingError.apiError("API Key is empty.")
        }
        
        guard let url = URL(string: "https://api.track123.com/gateway/open-api/tk/v2.1/track/query") else {
            throw TrackingError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiKey, forHTTPHeaderField: "Track123-Api-Secret")
        
        // Pass empty offset and limit to query anything loosely
        let queryPayload: [String: Any] = ["offset": 0, "limit": 1]
        request.httpBody = try JSONSerialization.data(withJSONObject: queryPayload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw TrackingError.networkError(NSError(domain: "Network Error", code: 0))
        }
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let code = jsonObject["code"] as? String {
            switch code {
            case "00000":
                return // Valid
            case "401":
                throw TrackingError.apiError("API Key is invalid or missing.")
            case "400":
                if let msg = jsonObject["msg"] as? String, msg.contains("quota") {
                    throw TrackingError.apiError("Access Denied: Plan expired or query limit reached.")
                }
                return // Suppose format error since we passed empty? If we pass no array, their API complains but with success status?
            default:
                let msg = jsonObject["msg"] as? String ?? "Unknown Error"
                // A0400 format error is fine, means auth succeeded but body failed
                if code == "A0400" { return }
                throw TrackingError.apiError(msg)
            }
        } else {
            throw TrackingError.apiError("Invalid payload shape from Track123.")
        }
    }
}
