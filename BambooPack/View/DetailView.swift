import SwiftUI

struct DetailView: View {
    @ObservedObject var parcel: Parcel
    @StateObject private var viewModel = ParcelViewModel()
    
    // State to control the Full History sheet
    @State private var showFullHistory = false
    
    // Smart Scraper State
    @State private var showScraperSheet = false
    @State private var scraperURL: URL?
    
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let tracking = parcel.trackingNumber, !tracking.isEmpty,
                       let carrier = parcel.carrier {
                        // Activate Smart Scraper
                        if let url = SmartScraperLogic.getTrackingURL(carrier: carrier, trackingNumber: tracking) {
                            self.scraperURL = url
                            self.showScraperSheet = true
                        }
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showFullHistory) {
            TrackingHistoryView(parcel: parcel, viewModel: viewModel)
        }
        .sheet(isPresented: $showScraperSheet) {
            if let url = scraperURL {
                WebViewContainer(url: url) { scrapedText in
                    // Logic: Parse the text
                    if let result = SmartScraperLogic.parseTrackingStatus(from: scrapedText) {
                        print("Smart Scraper Found: \(result.status)")
                        
                        // Update Parcel
                        // Note: WebViewContainer is on Main Thread (UI), so this is safe
                        viewModel.addTrackingEvent(
                            parcel: parcel,
                            description: result.description ?? "Status Updated via Smart Scraper",
                            location: nil,
                            status: result.status
                        )
                        
                        // Close Sheet on success
                        showScraperSheet = false
                    }
                }
                .frame(minWidth: 500, minHeight: 600)
            }
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
                    
                    if let lastUpdated = parcel.lastUpdated {
                        Text(lastUpdated.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
    @ObservedObject var viewModel: ParcelViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                let events = viewModel.getTrackingEvents(for: parcel)
                if events.isEmpty {
                    ContentUnavailableView("No History", systemImage: "shippingbox", description: Text("No tracking updates found yet."))
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
