import SwiftUI

enum SidebarCategory: String, CaseIterable, Identifiable {
    case incoming = "Incoming"
    case outgoing = "Outgoing"
    case archive = "Archive"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .incoming: return "tray.and.arrow.down"
        case .outgoing: return "tray.and.arrow.up"
        case .archive: return "archivebox"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarCategory?
    
    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarCategory.allCases) { category in
                Label(category.rawValue, systemImage: category.icon)
                    .tag(category)
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Bamboo Pack")
    }
}
