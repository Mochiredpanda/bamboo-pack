import SwiftUI

struct AddParcelSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var viewModel = ParcelViewModel()
    
    @State private var title: String = ""
    @State private var trackingNumber: String = ""
    @State private var direction: ParcelDirection
    @State private var notes: String = ""
    
    init(defaultDirection: ParcelDirection = .incoming) {
        _direction = State(initialValue: defaultDirection)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title (e.g. New Keyboard)", text: $title)
                    TextField("Tracking Number", text: $trackingNumber)
                    Picker("Direction", selection: $direction) {
                        ForEach(ParcelDirection.allCases, id: \.self) { direction in
                            Text(direction.title).tag(direction)
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
                            direction: direction, 
                            notes: notes
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || trackingNumber.isEmpty)
                }
            }
        }
    }
}
