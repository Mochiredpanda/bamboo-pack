import SwiftUI

struct DetailView: View {
    @ObservedObject var parcel: Parcel
    @StateObject private var viewModel = ParcelViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Tracking Info")) {
                TextField("Title", text: Binding(
                    get: { parcel.title ?? "" },
                    set: { parcel.title = $0 }
                ))
                
                HStack {
                    Text("Tracking Number")
                    Spacer()
                    Text(parcel.trackingNumber ?? "N/A")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Carrier")
                    Spacer()
                    Text(parcel.carrier ?? "Unknown")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Status")) {
                Picker("Status", selection: Binding(
                    get: { parcel.statusEnum },
                    set: { viewModel.updateStatus(parcel: parcel, status: $0) }
                )) {
                    ForEach(ParcelStatus.allCases, id: \.self) { status in
                        Label(status.title, systemImage: status.icon).tag(status)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: Binding(
                    get: { parcel.notes ?? "" },
                    set: { parcel.notes = $0 }
                ))
                .frame(minHeight: 100)
            }
            
            Section {
                Button(parcel.archived ? "Unarchive" : "Archive") {
                    viewModel.toggleArchive(parcel: parcel)
                }
                .foregroundColor(parcel.archived ? .blue : .red)
            }
        }
        .navigationTitle(parcel.title ?? "Details")
        .frame(minWidth: 300)
    }
}
