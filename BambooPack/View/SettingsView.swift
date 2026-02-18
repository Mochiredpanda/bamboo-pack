import SwiftUI

struct SettingsView: View {
    @AppStorage("tracking_api_key") private var apiKey: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tracking API") {
                    Text("Bamboo Pack supports real-time tracking via 17TRACK API (or compatible).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    if apiKey.isEmpty {
                        Text("Using Mock Data (Development Mode)")
                            .foregroundColor(.orange)
                            .font(.caption)
                    } else {
                        Text("Using Real API")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 300, minHeight: 200)
        }
    }
}
