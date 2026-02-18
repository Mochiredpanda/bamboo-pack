import SwiftUI
import CoreData

struct ParcelListView: View {
    var category: SidebarCategory
    @Binding var selection: Parcel?
    
    @FetchRequest var parcels: FetchedResults<Parcel>
    @State private var showingAddSheet = false
    
    init(category: SidebarCategory, selection: Binding<Parcel?>) {
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
            ForEach(parcels) { parcel in
                NavigationLink(value: parcel) {
                    ParcelRowView(parcel: parcel)
                }
                .contextMenu {
                    Button {
                        // Toggle Archive logic inline or via ViewModel if available
                        // Since we are in a simple view without the full VM, we do it directly:
                        parcel.archived.toggle()
                        parcel.lastUpdated = Date()
                        try? PersistenceController.shared.container.viewContext.save()
                    } label: {
                        Label(parcel.archived ? "Unarchive" : "Archive", systemImage: parcel.archived ? "arrow.uturn.backward.square" : "archivebox")
                    }
                    
                    Button(role: .destructive) {
                        PersistenceController.shared.container.viewContext.delete(parcel)
                        try? PersistenceController.shared.container.viewContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: deleteParcels)
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
    
    private func deleteParcels(offsets: IndexSet) {
        withAnimation {
            offsets.map { parcels[$0] }.forEach(PersistenceController.shared.container.viewContext.delete)
            
            do {
                try PersistenceController.shared.container.viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
