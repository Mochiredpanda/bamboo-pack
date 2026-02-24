import SwiftUI

struct SettingsView: View {
    @AppStorage("selected_api_provider") private var selectedProvider: APIProvider = .trackingmore
    @State private var apiKey: String = ""
    @Environment(\.dismiss) var dismiss
    
    enum ValidationStatus: Equatable {
        case idle
        case validating
        case valid(APIProvider)
        case invalid(String)
    }
    
    @State private var validationStatus: ValidationStatus = .idle
    
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
                    .onChange(of: selectedProvider) {
                        loadApiKey(for: selectedProvider)
                        Task { await validateCurrentKey() }
                    }
                    
                    HStack {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: apiKey) {
                                if validationStatus != .idle {
                                    validationStatus = .idle
                                }
                            }
                            .onSubmit {
                                saveApiKey(apiKey, for: selectedProvider)
                                Task { await validateCurrentKey() }
                            }
                        
                        Button {
                            saveApiKey(apiKey, for: selectedProvider)
                            Task { await validateCurrentKey() }
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(apiKey.isEmpty ? .secondary : .accentColor)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                        .disabled(apiKey.isEmpty)
                    }
                    
                    if apiKey.isEmpty {
                        Text("Please enter an API Key to validate.")
                            .foregroundColor(.orange)
                            .font(.caption)
                    } else {
                        switch validationStatus {
                        case .idle:
                            Text("Confirm to validate...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        case .validating:
                            HStack {
                                ProgressView().controlSize(.mini)
                                Text("Validating...")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        case .valid(let provider):
                            Text("API Validated (\(provider.rawValue))")
                                .foregroundColor(.green)
                                .font(.caption)
                        case .invalid(let errorMessage):
                            Text("Validation Failed: \(errorMessage)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
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
                Task { await validateCurrentKey() }
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
    
    @MainActor
    private func validateCurrentKey() async {
        guard !apiKey.isEmpty else {
            validationStatus = .idle
            return
        }
        
        validationStatus = .validating
        do {
            switch selectedProvider {
            case .trackingmore:
                try await TrackingmoreService.validateKey(apiKey: apiKey)
                validationStatus = .valid(selectedProvider)
            default:
                // Other providers not implemented validation yet
                validationStatus = .valid(selectedProvider)
            }
        } catch let error as TrackingError {
            switch error {
            case .apiError(let msg):
                validationStatus = .invalid(msg)
            default:
                validationStatus = .invalid(error.localizedDescription)
            }
        } catch {
            validationStatus = .invalid(error.localizedDescription)
        }
    }
}
