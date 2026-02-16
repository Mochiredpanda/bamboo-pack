import SwiftUI

struct AddParcelSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var viewModel = ParcelViewModel()
    
    // Form States
    @State private var title: String = ""
    @State private var status: ParcelStatus = .ordered
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
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title (e.g. New Keyboard)", text: $title)
                    
                    // Status Picker (Ordered vs Shipped for new items)
                    Picker("Status", selection: $status) {
                        Text("Ordered").tag(ParcelStatus.ordered)
                        Text("Shipped").tag(ParcelStatus.shipped)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if status == .ordered {
                        TextField("Order Number (Optional)", text: $orderNumber)
                    } else {
                        TextField("Tracking Number", text: $trackingNumber)
                        
                        Picker("Carrier", selection: $carrier) {
                            ForEach(CarrierDetector.Carrier.allCases) { carrier in
                                Text(carrier.name).tag(carrier)
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Parcel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addParcel(
                            title: title,
                            trackingNumber: trackingNumber,
                            status: status,
                            direction: direction,
                            orderNumber: orderNumber,
                            carrier: carrier,
                            notes: notes
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
    
    var isSaveDisabled: Bool {
        if title.isEmpty { return true }
        if status == .shipped && trackingNumber.isEmpty { return true }
        return false
    }
}
