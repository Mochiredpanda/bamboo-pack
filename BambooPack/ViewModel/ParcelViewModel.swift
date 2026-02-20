import Foundation
import CoreData
import SwiftUI
import Combine

class ParcelViewModel: ObservableObject {
    
    private let viewContext = PersistenceController.shared.container.viewContext
    
    @Published var isLoading = false
    
    // Published properties can be used if we want to manually manage lists, 
    // but typically we use @FetchRequest in Views. 
    // This ViewModel will focus on Logic and CRUD actions.
    
    // MARK: - Tracking Service Integration
    
    private let trackingService: TrackingService
    
    init(service: TrackingService = MockTrackingService()) {
        self.trackingService = service
    }
    
    @MainActor
    func refreshTracking(for parcel: Parcel) async {
        guard let trackingNumber = parcel.trackingNumber, !trackingNumber.isEmpty,
              let carrier = parcel.carrier else {
            return
        }
        
        isLoading = true
        
        do {
            // Check if we should use Real Service based on settings
            // For MVP, we can toggle this or default to Mock if no key
            // Ideally, we'd inject the correct service instance at init time.
            // For this demo, let's just stick with the injected service (Mock by default)
            // or switch to Real if a key exists:
            
            let serviceToUse: TrackingService
            if let apiKey = UserDefaults.standard.string(forKey: "tracking_api_key"), !apiKey.isEmpty {
                 serviceToUse = RealTrackingService()
            } else {
                 serviceToUse = MockTrackingService()
            }
            
            let info = try await serviceToUse.fetchTrackingInfo(carrier: carrier, trackingNumber: trackingNumber)
            
            // Update Core Data
            parcel.statusEnum = info.status
            parcel.lastUpdated = Date()
            
            // Serialize History
            if let encodedHistory = try? JSONEncoder().encode(info.events),
               let historyString = String(data: encodedHistory, encoding: .utf8) {
                parcel.trackingHistory = historyString
            }
            
            saveContext()
            
        } catch {
            print("Tracking Error: \(error.localizedDescription)")
            // Optionally set error state
        }
        
        isLoading = false
    }
    
    // Helper to decode history for View consumption
    func getTrackingEvents(for parcel: Parcel) -> [TrackingEvent] {
        guard let historyString = parcel.trackingHistory,
              let data = historyString.data(using: .utf8) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([TrackingEvent].self, from: data)
        } catch {
            print("Failed to decode history: \(error)")
            return []
        }
    }
    
    // Helper to append a single event (used by Smart Scraper)
    func addTrackingEvent(parcel: Parcel, description: String, location: String?, status: ParcelStatus) {
        var currentEvents = getTrackingEvents(for: parcel)
        
        // Create new event
        let newEvent = TrackingEvent(
            id: UUID(),
            timestamp: Date(),
            description: description,
            location: location,
            status: status
        )
        
        // Prepend (newest first) or Append? Usually newest first for history.
        // Let's prepend to match the sort order in UI
        currentEvents.insert(newEvent, at: 0)
        
        // Encode
        if let encodedHistory = try? JSONEncoder().encode(currentEvents),
           let historyString = String(data: encodedHistory, encoding: .utf8) {
            parcel.trackingHistory = historyString
        }
        
        // 2. CRITICAL: Update the parent parcel's core properties
        parcel.statusEnum = status // This moves it to the correct Section in ListView
        parcel.lastUpdated = Date()     // This forces the ListView to sort it to the top
        
        // 3. CRITICAL: Save the context to notify @FetchRequest
        do {
            try viewContext.save()
        } catch {
            print("Failed to save tracking event: \(error)")
        }
    }

    // MARK: - Core Data Operations

    func addParcel(
        title: String,
        trackingNumber: String,
        direction: ParcelDirection,
        orderNumber: String?,
        carrier: CarrierDetector.Carrier,
        notes: String?,
        recipient: String? = nil,
        purpose: String? = nil,
        estimatedDeliveryDate: Date? = nil,
        productURL: String? = nil
    ) {
        let newParcel = Parcel(context: viewContext)
        newParcel.id = UUID()
        // Sanitize
        newParcel.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newParcel.trackingNumber = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        newParcel.orderNumber = orderNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        newParcel.dateAdded = Date()
        newParcel.lastUpdated = Date()
        newParcel.directionEnum = direction
        newParcel.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        newParcel.archived = false
        
        // New Fields
        newParcel.recipient = recipient?.trimmingCharacters(in: .whitespacesAndNewlines)
        newParcel.purpose = purpose?.trimmingCharacters(in: .whitespacesAndNewlines)
        newParcel.estimatedDeliveryDate = estimatedDeliveryDate
        newParcel.productURL = productURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Initial Status Logic
        // If tracking number is present -> Pre-Shipment (or In Transit if we knew, but Pre-Shipment is safe default)
        // If empty -> Ordered (Incoming) or Draft (Outgoing)
        if !trackingNumber.isEmpty {
            newParcel.statusEnum = .preShipment
        } else {
            newParcel.statusEnum = direction == .incoming ? .ordered : .draft
        }
        
        // Carrier Logic
        if carrier == .auto {
            if !trackingNumber.isEmpty {
                let detected = CarrierDetector.detect(trackingNumber: trackingNumber)
                newParcel.carrier = detected.name
            } else {
                newParcel.carrier = nil
            }
        } else {
            newParcel.carrier = carrier.name
            // If explicit carrier but no tracking, can still be ordered/draft
        }
        
        saveContext()
    }
    
    func updateStatus(parcel: Parcel, status: ParcelStatus) {
        parcel.statusEnum = status
        parcel.lastUpdated = Date()
        saveContext()
    }
    
    func toggleArchive(parcel: Parcel) {
        parcel.archived.toggle()
        parcel.lastUpdated = Date()
        saveContext()
    }
    
    func deleteParcels(offsets: IndexSet, parcels: FetchedResults<Parcel>) {
        offsets.map { parcels[$0] }.forEach(viewContext.delete)
        saveContext()
    }
    
    func deleteParcel(_ parcel: Parcel) {
        viewContext.delete(parcel)
        saveContext()
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
