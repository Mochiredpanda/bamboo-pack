import SwiftUI

enum SidebarCategory: String, CaseIterable, Identifiable {
    case incoming = "Incoming"
    case outgoing = "Outgoing"
    case archive = "Archive"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .incoming: return "shippingbox"
        case .outgoing: return "arrow.up.circle"
        case .archive: return "archivebox"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarCategory?
    
    @State private var showingSettings = false
    
    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarCategory.allCases) { category in
                Label(category.rawValue, systemImage: category.icon)
                    .tag(category)
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Bamboo Pack")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingSettings = true }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
             SettingsView()
        }
    }
}
