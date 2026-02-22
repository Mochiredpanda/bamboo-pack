import SwiftUI
import Combine

struct DetailView: View {
    @ObservedObject var parcel: Parcel
    @StateObject private var viewModel = ParcelViewModel()
    @Environment(\.openWindow) private var openWindow
    
    // State to control the Full History sheet
    @State private var showFullHistory = false
    
    // Tracking Refresh UI State
    @State private var isRefreshing = false
    @State private var showToast = false
    
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
                    extendedFields
                }
                
                Section("Notes") {
                    notesEditor
                }
                
                
                Section {
                    archiveButton
                    deleteButton
                }
            }
            .formStyle(.grouped)
        }
        .toast(isShowing: $showToast, message: "Status Up-to-Date")
        .navigationTitle(parcel.title ?? "Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isRefreshing = true
                        await viewModel.refreshTracking(for: parcel)
                        isRefreshing = false
                        showToast = true
                    }
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 4)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showFullHistory) {
            TrackingHistoryView(parcel: parcel, viewModel: viewModel)
        }
    }
    
    // MARK: - Subviews
    
    var statusColor: Color {
        switch parcel.statusEnum {
        case .delivered: return .green
        case .exception, .suspended: return .red
        default: return .blue
        }
    }
    
    // MARK: - Latest Tracking Card
    // separated from the main form
    private var latestTrackingCard: some View {
        let events = viewModel.getTrackingEvents(for: parcel)
        let latestEvent = events.first
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LATEST UPDATE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    if let event = latestEvent {
                        Text(event.description)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack {
                            if let location = event.location {
                                Text(location)
                            }
                            Text("•")
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    } else {
                        Text("Update Needed")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Pull or tap Refresh to check status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: parcel.statusEnum.icon)
                    .font(.system(size: 34))
                    .foregroundColor(statusColor)
            }
            
            Divider()
            
            // Replaced History Link with Expected Delivery readout
            HStack {
                if parcel.statusEnum == .delivered {
                    if let deliveryDate = latestEvent?.timestamp {
                        Text("Delivered at \(deliveryDate.formatted(date: .abbreviated, time: .shortened))")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else {
                        Text("Delivered")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                } else {
                    if let expectedDate = parcel.estimatedDeliveryDate {
                         Text("Expected: \(expectedDate.formatted(date: .abbreviated, time: .omitted))")
                             .fontWeight(.semibold)
                    } else {
                         Text("Expected Date Unknown")
                             .fontWeight(.regular)
                    }
                }
                Spacer()
            }
            // Apply blue color only if not delivered
            .foregroundColor(parcel.statusEnum == .delivered ? .green : .blue)
            
            /*
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
            */
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var trackingNumberField: some View {
        TextField("Tracking Number", text: Binding(
            get: { parcel.trackingNumber ?? "" },
            set: { newValue in
                let oldValue = parcel.trackingNumber ?? ""
                
                // If clearing a previously tracked parcel
                if newValue.isEmpty && !oldValue.isEmpty {
                    // If it was already in an active state (not just ordered/draft)
                    // We suspend it instead of deleting the number entirely? 
                    // Or we allow it but prompt validity? 
                    // Requirement: "do not delete or unlink ... freeze it to 'suspended'"
                    
                    // Ideally we'd show an alert, but inside a Binding set that's hard.
                    // Implementation: Allow clearing text field, but Logic sets status to Suspended if it WAS active
                    if parcel.statusEnum != .ordered && parcel.statusEnum != .draft {
                         parcel.statusEnum = .suspended
                    }
                }
                
                parcel.trackingNumber = newValue
                
                // Auto-Workflow: If adding a tracking number to an untracked (or suspended) parcel
                if oldValue.isEmpty && !newValue.isEmpty {
                    // 1. Update Status to 'Pre-Shipment' (Active)
                    if parcel.statusEnum == .ordered || parcel.statusEnum == .draft || parcel.statusEnum == .suspended {
                        parcel.statusEnum = .preShipment
                    }
                    
                    // 2. Auto-Detect Carrier if not already set
                    if parcel.carrier == nil || parcel.carrier == "Auto" {
                        let detected = CarrierDetector.detect(trackingNumber: newValue)
                        if detected != .auto {
                            parcel.carrier = detected.name
                        }
                    }
                    
                    // 3. Trigger "Update Needed"
                    parcel.lastUpdated = Date()
                }
                
                viewModel.saveContext()
            }
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
    
    // New Fields
    private var extendedFields: some View {
        Group {
            if parcel.directionEnum == .outgoing {
                TextField("Recipient", text: Binding(
                    get: { parcel.recipient ?? "" },
                    set: { parcel.recipient = $0 }
                ))
                TextField("Purpose", text: Binding(
                    get: { parcel.purpose ?? "" },
                    set: { parcel.purpose = $0 }
                ))
            }
            
            if let expectedDate = parcel.estimatedDeliveryDate {
                HStack {
                    Text("Expected Delivery")
                    Spacer()
                    Text(expectedDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
            }
        }
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
    
    @State private var showDeleteConfirmation = false
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Label("Delete Parcel", systemImage: "trash")
        }
        .foregroundColor(.red)
        .alert("Delete Parcel?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteParcel(parcel)
                // Attempt to dismiss if pushed, though in SplitView selection clearing is handled by parent usually
                // This prevents immediate crash effectively by assuming parent updates
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this parcel? This action cannot be undone.")
        }
    }
} 

// MARK: - Subview: Tracking History
// A simple view to show the full list when the button is clicked
struct TrackingHistoryView: View {
    let parcel: Parcel
    @ObservedObject var viewModel: ParcelViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                let events = viewModel.getTrackingEvents(for: parcel)
                if events.isEmpty {
                    ContentUnavailableView("Needs to be updated", systemImage: "arrow.clockwise", description: Text("Pull or tap Refresh to check status."))
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading) {
                            Text(event.description)
                                .font(.headline)
                            
                            HStack {
                                if let location = event.location {
                                    Text(location)
                                }
                                Text("•")
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
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
