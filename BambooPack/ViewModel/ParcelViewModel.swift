import Foundation
import CoreData
import SwiftUI
import Combine

class ParcelViewModel: ObservableObject {
    
    private let viewContext = PersistenceController.shared.container.viewContext
    
    @Published var isLoading = false
    
    // MARK: - Batch Sync (New Workflow)
    
    @MainActor
    func syncAllActiveParcels() async {
        isLoading = true
        
        // 1. Fetch Active Parcels
        let request: NSFetchRequest<Parcel> = Parcel.fetchRequest()
        // Simple heuristic: not delivered, not archived, not exception
        request.predicate = NSPredicate(format: "archived == NO AND statusEnum_raw != %@ AND statusEnum_raw != %@", 
                                        ParcelStatus.delivered.rawValue, 
                                        ParcelStatus.exception.rawValue)
        
        do {
            let activeParcels = try viewContext.fetch(request)
            
            // 2. Execute tracking sync
            let service = TrackingmoreService()
            let synchronizedResults = try await service.syncActiveParcels(activeParcels)
            
            // 3. Update Core Data from Normalized Models
            for (normalizedInfo, timeline) in synchronizedResults {
                guard let parcelToUpdate = activeParcels.first(where: { $0.id == normalizedInfo.entryId }) else { continue }
                
                parcelToUpdate.statusEnum = normalizedInfo.status
                parcelToUpdate.lastUpdated = Date()
                
                if let encodedHistory = try? JSONEncoder().encode(timeline),
                   let historyString = String(data: encodedHistory, encoding: .utf8) {
                    parcelToUpdate.trackingHistory = historyString
                }
            }
            
            saveContext()
            
        } catch {
            print("Batch Sync Error: \(error.localizedDescription)")
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
