import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: SidebarCategory? = .incoming
    @State private var selectedParcel: Parcel?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedCategory)
        } content: {
            if let category = selectedCategory {
                ParcelListView(category: category, selection: $selectedParcel)
            } else {
                Text("Select a category")
            }
        } detail: {
            if let parcel = selectedParcel {
                DetailView(parcel: parcel)
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
