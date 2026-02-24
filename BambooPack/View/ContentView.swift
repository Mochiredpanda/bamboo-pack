import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: SidebarCategory? = .incoming
    @State private var selectedParcels: Set<Parcel> = []
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedCategory)
        } content: {
            if let category = selectedCategory {
                ParcelListView(category: category, selection: $selectedParcels)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            } else {
                Text("Select a category")
            }
        } detail: {
            if selectedParcels.count == 1, let parcel = selectedParcels.first {
                DetailView(parcel: parcel)
            } else if selectedParcels.count > 1 {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("\(selectedParcels.count) parcels selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Select a parcel")
                    .foregroundColor(.secondary)
            }
        }
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
