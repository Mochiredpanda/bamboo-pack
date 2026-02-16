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
    
    func addParcel(title: String, trackingNumber: String, direction: ParcelDirection, notes: String?) {
        let newParcel = Parcel(context: viewContext)
        newParcel.id = UUID()
        newParcel.title = title
        newParcel.trackingNumber = trackingNumber
        newParcel.dateAdded = Date()
        newParcel.lastUpdated = Date()
        newParcel.directionEnum = direction
        newParcel.statusEnum = .ordered // Default status
        newParcel.notes = notes
        newParcel.archived = false
        
        // Auto-detect carrier
        let detectedCarrier = CarrierDetector.detect(trackingNumber: trackingNumber)
        newParcel.carrier = detectedCarrier.name
        
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
