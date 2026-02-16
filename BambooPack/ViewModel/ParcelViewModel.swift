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
    
    func addParcel(title: String, trackingNumber: String, status: ParcelStatus, direction: ParcelDirection, orderNumber: String?, carrier: CarrierDetector.Carrier, notes: String?) {
        let newParcel = Parcel(context: viewContext)
        newParcel.id = UUID()
        newParcel.title = title
        newParcel.trackingNumber = trackingNumber.isEmpty ? nil : trackingNumber
        newParcel.orderNumber = orderNumber
        newParcel.dateAdded = Date()
        newParcel.lastUpdated = Date()
        newParcel.statusEnum = status
        newParcel.directionEnum = direction
        newParcel.notes = notes
        newParcel.archived = false
        
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
    
    private func saveContext() {
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
