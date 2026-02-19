import SwiftUI

struct AddParcelSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // Updated from presentationMode for iOS 15+/macOS 12+
    
    @StateObject private var viewModel = ParcelViewModel()
    
    // Form States
    @State private var carrier: CarrierDetector.Carrier = .auto
    @State private var direction: ParcelDirection
    
    // Core Fields
    @State private var trackingNumber: String = ""
    @State private var title: String = "" // Package Name
    @State private var notes: String = ""
    
    // Optional Fields
    @State private var orderNumber: String = ""
    @State private var recipient: String = ""
    @State private var purpose: String = "" // Could be a picker later
    @State private var estimatedDeliveryDate: Date = Date()
    @State private var hasEstimatedDate: Bool = false
    
    init(defaultDirection: ParcelDirection = .incoming) {
        _direction = State(initialValue: defaultDirection)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Core Tracking Section
                Section {
                    TextField("Tracking Number", text: $trackingNumber)
                    
                    Picker("Carrier", selection: $carrier) {
                        ForEach(CarrierDetector.Carrier.allCases) { carrier in
                            Text(carrier.name).tag(carrier)
                        }
                    }
                } header: {
                    Text("Tracking Info")
                } footer: {
                    if trackingNumber.isEmpty {
                        Text("Without a tracking number, this will be saved as \(direction == .incoming ? "'Ordered'" : "'Draft'")")
                    } else {
                        Text("Will be saved as 'Pre-Shipment' to start tracking.")
                    }
                }
                
                // MARK: - Details Section
                Section {
                    TextField("Package Name (Optional)", text: $title)
                    
                    if direction == .incoming {
                        TextField("Order Number (Optional)", text: $orderNumber)
                    }
                    
                    if direction == .outgoing {
                        TextField("Recipient (Optional)", text: $recipient)
                        TextField("Purpose (e.g. Return, Gift)", text: $purpose)
                    }
                    
                    Toggle("Has Estimated Delivery?", isOn: $hasEstimatedDate)
                    if hasEstimatedDate {
                        DatePicker("Expected Delivery", selection: $estimatedDeliveryDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Details")
                }
                
                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80, alignment: .top)
                        .frame(maxHeight: .infinity)
                } header: {
                    Text("Notes")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(direction == .incoming ? "Add Incoming Parcel" : "Add Outgoing Parcel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveParcel() }
                        .fontWeight(.bold)
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 450, maxWidth: .infinity,
               minHeight: 500, idealHeight: 600, maxHeight: .infinity)
    }
    
    private func saveParcel() {
        viewModel.addParcel(
            title: title,
            trackingNumber: trackingNumber,
            direction: direction,
            orderNumber: orderNumber,
            carrier: carrier,
            notes: notes,
            recipient: recipient,
            purpose: purpose,
            estimatedDeliveryDate: hasEstimatedDate ? estimatedDeliveryDate : nil
        )
        dismiss()
    }
}
