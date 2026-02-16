import SwiftUI

struct DetailView: View {
    @ObservedObject var parcel: Parcel
    @StateObject private var viewModel = ParcelViewModel()
    
    // State to control the Full History sheet
    @State private var showFullHistory = false
    
    var body: some View {
        Form {
            // MARK: - 1. Latest Tracking Card
            // This section is styled to look like a "Hero" card
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LATEST UPDATE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            // ⚠️ Assumption: You have a way to get the latest status text
                            Text(parcel.statusEnum.title) 
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Test City, CA • Date, Time") // Placeholder
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status Icon
                        Image(systemName: parcel.statusEnum.icon)
                            .font(.system(size: 34))
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                    
                    Button {
                        showFullHistory = true
                    } label: {
                        HStack {
                            Text("View Full History")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .contentShape(Rectangle()) // Makes the whole row tappable
                    }
                    .buttonStyle(.plain) // Removes default button styling to blend in
                    .foregroundColor(.blue)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor)) // subtle distinct background
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)   
            .listRowInsets(EdgeInsets()) // Removes default List padding to let card fill space
            .listRowBackground(Color.clear) // Removes default gray row background

            // Core Info
            Section("Shipment Details") {
                // Editable Tracking Number
                TextField("Tracking Number", text: Binding(
                    get: { parcel.trackingNumber ?? "" },
                    set: { parcel.trackingNumber = $0 }
                ))
                
                // Editable Carrier Picker
                // We bridge the String in CoreData to the Enum for the picker
                Picker("Carrier", selection: Binding(
                    get: { 
                        // Match the string to the Enum, or default to .auto
                        CarrierDetector.Carrier.allCases.first { $0.name == parcel.carrier } ?? .auto 
                    },
                    set: { 
                        // Save the Enum name back to the string
                        parcel.carrier = $0.name 
                    }
                )) {
                    ForEach(CarrierDetector.Carrier.allCases) { carrier in
                        Text(carrier.name).tag(carrier)
                    }
                }
                
                // Editable Title
                TextField("Package Name", text: Binding(
                    get: { parcel.title ?? "" },
                    set: { parcel.title = $0 }
                ))
            }
            
            // MARK: - 3. Notes (Resizable)
            Section("Notes") {
                TextEditor(text: Binding(
                    get: { parcel.notes ?? "" },
                    set: { parcel.notes = $0 }
                ))
                .frame(minHeight: 100, alignment: .top)
            }
            
            // MARK: - 4. Actions
            Section {
                Button {
                    viewModel.toggleArchive(parcel: parcel)
                } label: {
                    Label(
                        parcel.archived ? "Unarchive Parcel" : "Archive Parcel",
                        systemImage: parcel.archived ? "arrow.uturn.backward.square" : "archivebox"
                    )
                }
                .foregroundColor(parcel.archived ? .blue : .red)
            }
        }
        .formStyle(.grouped) // ⭐️ Key for Consistency with AddSheet
        .navigationTitle(parcel.title ?? "Details")
        .frame(minWidth: 400, minHeight: 500) // Reasonable default size
        
        // The Sheet for Full History
        .sheet(isPresented: $showFullHistory) {
            TrackingHistoryView(parcel: parcel)
        }
    }
}

// MARK: - Subview: Tracking History
// A simple view to show the full list when the button is clicked
struct TrackingHistoryView: View {
    let parcel: Parcel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Mock Data Loop - Replace with parcel.historyArray
                ForEach(0..<5) { i in
                    VStack(alignment: .leading) {
                        Text("Arrived at facility")
                            .font(.headline)
                        Text("Seattle, WA • Feb \(14-i)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Tracking History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .frame(minWidth: 350, minHeight: 400)
        }
    }
}