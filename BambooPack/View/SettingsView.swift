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
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                        Text("\(version) (Beta)")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/Mochiredpanda/bamboo-pack")!) {
                        HStack {
                            Image("GitHubIcon")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.primary)
                                .frame(width: 16, height: 16)
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "gear")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        if let url = URL(string: "mailto:mochiredpanda0@gmail.com?subject=Bamboo%20Pack%20Feedback") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Made by Mochi Red Panda & Friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
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
