import SwiftUI

struct DetailView: View {
    @ObservedObject var parcel: Parcel
    @StateObject private var viewModel = ParcelViewModel()
    
    // State to control the Full History sheet
    @State private var showFullHistory = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Latest Tracking Card
            // Hero card style
            latestTrackingCard
                .padding()

            // MARK: - 2. Core Info Form
            Form {
                Section("Shipment Details") {
                    trackingNumberField
                    carrierPicker
                    titleField
                }
                
                Section("Notes") {
                    notesEditor
                }
                
                Section {
                    archiveButton
                }
            }
            .formStyle(.grouped)
        }
        .navigationTitle(parcel.title ?? "Details")
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showFullHistory) {
            TrackingHistoryView(parcel: parcel)
        }
    }
    
    // MARK: - Subviews
    // MARK: - Latest Tracking Card
    // separated from the main form
    private var latestTrackingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LATEST UPDATE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(parcel.statusEnum.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Test City, CA • Date, Time") // Placeholder
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var trackingNumberField: some View {
        TextField("Tracking Number", text: Binding(
            get: { parcel.trackingNumber ?? "" },
            set: { parcel.trackingNumber = $0 }
        ))
    }
    
    private var carrierPicker: some View {
        Picker("Carrier", selection: Binding(
            get: {
                CarrierDetector.Carrier.allCases.first { $0.name == parcel.carrier } ?? .auto
            },
            set: {
                parcel.carrier = $0.name
            }
        )) {
            ForEach(CarrierDetector.Carrier.allCases) { carrier in
                Text(carrier.name).tag(carrier)
            }
        }
    }
    
    private var titleField: some View {
        TextField("Package Name", text: Binding(
            get: { parcel.title ?? "" },
            set: { parcel.title = $0 }
        ))
    }
    
    private var notesEditor: some View {
        TextEditor(text: Binding(
            get: { parcel.notes ?? "" },
            set: { parcel.notes = $0 }
        ))
        .frame(minHeight: 100, alignment: .top)
    }
    
    private var archiveButton: some View {
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
