import SwiftUI

struct SettingsView: View {
    @AppStorage("selected_api_provider") private var selectedProvider: APIProvider = .trackingmore
    @State private var apiKey: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tracking API") {
                    Text("Select your preferred API provider and securely store your API key.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(APIProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .onChange(of: selectedProvider) { newValue in
                        loadApiKey(for: newValue)
                    }
                    
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: apiKey) { newValue in
                            saveApiKey(newValue, for: selectedProvider)
                        }
                    
                    if apiKey.isEmpty {
                        Text("Using Mock Data (Development Mode)")
                            .foregroundColor(.orange)
                            .font(.caption)
                    } else {
                        Text("Using Real API (\(selectedProvider.rawValue))")
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
            .onAppear {
                loadApiKey(for: selectedProvider)
            }
        }
    }
    
    private func loadApiKey(for provider: APIProvider) {
        let keyString: String? = KeychainHelper.shared.read(service: "com.bamboopack.api", account: provider.keychainAccount)
        if let key = keyString {
            apiKey = key
        } else {
            apiKey = ""
        }
    }
    
    private func saveApiKey(_ key: String, for provider: APIProvider) {
        if key.isEmpty {
            KeychainHelper.shared.delete(service: "com.bamboopack.api", account: provider.keychainAccount)
        } else {
            KeychainHelper.shared.save(key, service: "com.bamboopack.api", account: provider.keychainAccount)
        }
    }
}
