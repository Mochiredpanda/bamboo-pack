import SwiftUI

struct AddParcelSheet: View {
    // Environment & ViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ParcelViewModel()
    
    // Config
    @State private var direction: ParcelDirection
    
    // Core Fields
    @State private var trackingNumber: String = ""
    @State private var title: String = "" // Package Name
    @State private var notes: String = ""
    @State private var isNotesExpanded: Bool = false
    
    // Carrier Logic
    @State private var carrier: CarrierDetector.Carrier = .auto
    @State private var showCarrierPicker: Bool = false
    
    // Incoming Fields
    @State private var orderNumber: String = ""
    @State private var productURL: String = ""
    
    // Outgoing Fields
    @State private var recipient: String = ""
    @State private var purpose: String = "Gift" // Default
    let purposes = ["Gift", "Return", "Sale", "Business", "Personal"]
    
    init(defaultDirection: ParcelDirection = .incoming) {
        _direction = State(initialValue: defaultDirection)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if direction == .incoming {
                    incomingFormContent
                } else {
                    outgoingFormContent
                }
                
                // Folded Notes Section
                Section {
                    if isNotesExpanded {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    } else {
                        Button {
                            withAnimation { isNotesExpanded = true }
                        } label: {
                            Label("Add Notes", systemImage: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    if isNotesExpanded {
                        HStack {
                            Text("Notes")
                            Spacer()
                            Button {
                                withAnimation { isNotesExpanded = false }
                            } label: {
                                Text("Hide")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(direction == .incoming ? "Add Incoming" : "Add Outgoing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveParcel() }
                        .fontWeight(.bold)
                }
            }
            .onChange(of: trackingNumber) { newValue in
                detectCarrier(for: newValue)
            }
        }
        .frame(minWidth: 400, idealWidth: 450, maxWidth: .infinity,
               minHeight: 450, idealHeight: 550, maxHeight: .infinity)
    }
    
    // MARK: - Incoming Form
    private var incomingFormContent: some View {
        Group {
            Section {
                TextField("Package Name (Optional)", text: $title)
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Tracking Number", text: $trackingNumber)
                    if trackingNumber.isEmpty {
                        Text("Without a tracking number, this will be saved as 'Ordered'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Smart Carrier: Only show if detection fails AND tracking is present
                if showCarrierPicker {
                    Picker("Carrier", selection: $carrier) {
                        ForEach(CarrierDetector.Carrier.allCases) { carrier in
                            Text(carrier.name).tag(carrier)
                        }
                    }
                }
            } header: {
                Text("Tracking")
            }
            
            Section {
                TextField("Order Number", text: $orderNumber)
                TextField("Product URL", text: $productURL)
            } header: {
                Text("Package Info")
            }
        }
    }
    
    // MARK: - Outgoing Form
    private var outgoingFormContent: some View {
        Group {
            Section {
                TextField("Package Name", text: $title)
                
                Picker("Purpose", selection: $purpose) {
                    ForEach(purposes, id: \.self) { p in
                        Text(p).tag(p)
                    }
                }
                
                TextField("Recipient (Optional)", text: $recipient)
            } header: {
                Text("Package Info")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Tracking Number (Optional)", text: $trackingNumber)
                    if trackingNumber.isEmpty {
                        Text("Without a tracking number, this will be saved as 'Draft'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Tracking")
            }
        }
    }
    
    // MARK: - Logic
    
    private func detectCarrier(for number: String) {
        if number.isEmpty {
            showCarrierPicker = false
            carrier = .auto
            return
        }
        
        let detected = CarrierDetector.detect(trackingNumber: number)
        if detected == .auto {
            // Detection failed or unknown -> Ask user
            showCarrierPicker = true
        } else {
            // Found it -> Hide picker and set it
            showCarrierPicker = false
            carrier = detected
        }
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
            productURL: productURL
        )
        dismiss()
    }
}
