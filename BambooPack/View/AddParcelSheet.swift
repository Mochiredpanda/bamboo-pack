import SwiftUI

struct AddParcelSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // Updated from presentationMode for iOS 15+/macOS 12+
    
    @StateObject private var viewModel = ParcelViewModel()
    
    // Form States
    @State private var title: String = ""
    @State private var status: ParcelStatus = .shipped
    @State private var carrier: CarrierDetector.Carrier = .auto
    @State private var direction: ParcelDirection
    
    // Dynamic Fields
    @State private var trackingNumber: String = ""
    @State private var orderNumber: String = ""
    @State private var notes: String = ""
    
    init(defaultDirection: ParcelDirection = .incoming) {
        _direction = State(initialValue: defaultDirection)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Core Info Section
                Section {


                    Picker("Status", selection: $status) {
                        Text("Shipped").tag(ParcelStatus.shipped)
                        Text("Ordered").tag(ParcelStatus.ordered)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Shipment Details")
                }
                
                // MARK: - Tracking / Order Section
                Section {
                    if status == .ordered {
                        TextField("Order Number", text: $orderNumber)
                        // Add a subtext if it's truly optional
                    } else {
                        TextField("Tracking Number", text: $trackingNumber)
                        
                        Picker("Carrier", selection: $carrier) {
                            ForEach(CarrierDetector.Carrier.allCases) { carrier in
                                Text(carrier.name).tag(carrier)
                            }
                        }
                    }
                    
                    TextField("Package Name (Optional)", text: $title)
                } header: {
                    Text("Parcel Details")
                }
                
                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80, alignment: .top) // Minimum readable height
                        // This allows the text editor to grow if the form has extra space
                        .frame(maxHeight: .infinity) 
                } header: {
                    Text("Notes")
                }
            }
            .formStyle(.grouped) // Standardizes the look across platforms
            // 1. Navigation Title: Standard approach
            .navigationTitle("Add Parcel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveParcel()
                    }
                    .disabled(isSaveDisabled)
                    .fontWeight(.bold) // Visual cue that this is the primary action
                }
            }
        }
        // We set a minimum usable width, but allow it to grow.
        // We do not lock the height, allowing the user to resize the window vertically.
        .frame(minWidth: 400, idealWidth: 450, maxWidth: .infinity, 
               minHeight: 400, idealHeight: 550, maxHeight: .infinity)
    }
    
    private func saveParcel() {
        viewModel.addParcel(
            title: title,
            trackingNumber: trackingNumber,
            status: status,
            direction: direction,
            orderNumber: orderNumber,
            carrier: carrier,
            notes: notes
        )
        dismiss()
    }
    
    var isSaveDisabled: Bool {
        if status == .shipped && trackingNumber.isEmpty { return true }
        return false
    }
}
