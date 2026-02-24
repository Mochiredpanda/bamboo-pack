import SwiftUI
import CoreData

struct ParcelListView: View {
    var category: SidebarCategory
    @Binding var selection: Set<Parcel>
    
    @FetchRequest var parcels: FetchedResults<Parcel>
    @State private var showingAddSheet = false
    
    init(category: SidebarCategory, selection: Binding<Set<Parcel>>) {
        self.category = category
        self._selection = selection
        
        let predicate: NSPredicate
        switch category {
        case .incoming:
            predicate = NSPredicate(format: "direction == %d AND archived == NO", ParcelDirection.incoming.rawValue)
        case .outgoing:
            predicate = NSPredicate(format: "direction == %d AND archived == NO", ParcelDirection.outgoing.rawValue)
        case .archive:
            predicate = NSPredicate(format: "archived == YES")
        }
        
        _parcels = FetchRequest<Parcel>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Parcel.lastUpdated, ascending: false)],
            predicate: predicate,
            animation: .default)
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(ParcelStatus.StatusCategory.allCases, id: \.self) { category in
                let categoryParcels: [Parcel] = {
                    let filtered = parcels.filter { $0.statusEnum.category == category }
                    if category == .onTheWay {
                        return filtered.sorted {
                            let d1 = $0.estimatedDeliveryDate ?? Date.distantFuture
                            let d2 = $1.estimatedDeliveryDate ?? Date.distantFuture
                            return d1 < d2
                        }
                    }
                    return filtered
                }()
                
                if !categoryParcels.isEmpty {
                    Section(header: Text(category.rawValue)) {
                        ForEach(categoryParcels) { parcel in
                            NavigationLink(value: parcel) {
                                ParcelRowView(parcel: parcel)
                            }
                            .contextMenu {
                                let targets = selection.contains(parcel) ? Array(selection) : [parcel]
                                
                                Button {
                                    for p in targets {
                                        p.archived.toggle()
                                        p.lastUpdated = Date()
                                    }
                                    saveContext()
                                    if !targets.isEmpty {
                                        selection.subtract(targets) // Clear selection if archived so they disappear cleanly
                                    }
                                } label: {
                                    Label(targets.count > 1 ? "Archive \(targets.count) Parcels" : (parcel.archived ? "Unarchive" : "Archive"), systemImage: parcel.archived ? "arrow.uturn.backward.square" : "archivebox")
                                }
                                
                                Button(role: .destructive) {
                                    deleteParcels(targets)
                                    if !targets.isEmpty {
                                        selection.subtract(targets)
                                    }
                                } label: {
                                    Label(targets.count > 1 ? "Delete \(targets.count) Parcels" : "Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteParcelsOffsets(offsets: indexSet, in: categoryParcels)
                        }
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Parcel", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddParcelSheet(defaultDirection: category == .outgoing ? .outgoing : .incoming)
        }
    }
    
    private func deleteParcelsOffsets(offsets: IndexSet, in sourceArray: [Parcel]) {
        withAnimation {
            offsets.map { sourceArray[$0] }.forEach(PersistenceController.shared.container.viewContext.delete)
            saveContext()
        }
    }
    
    private func deleteParcels(_ targetParcels: [Parcel]) {
        withAnimation {
            targetParcels.forEach { PersistenceController.shared.container.viewContext.delete($0) }
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
