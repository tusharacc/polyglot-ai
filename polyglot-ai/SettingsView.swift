//
//  SettingsView.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKeys: [APIProvider: String] = [:]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Keys")) {
                    ForEach(APIProvider.allCases, id: \.self) { provider in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(provider.displayName)
                                    .font(.headline)
                                Spacer()
                                if KeychainManager.shared.hasApiKey(for: provider) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            SecureField("Enter API Key", text: Binding(
                                get: { apiKeys[provider] ?? "" },
                                set: { apiKeys[provider] = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                Button("Save") {
                                    saveApiKey(for: provider)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(apiKeys[provider]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                                
                                if KeychainManager.shared.hasApiKey(for: provider) {
                                    Button("Delete") {
                                        deleteApiKey(for: provider)
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(footer: Text("API keys are stored securely in your device's keychain and never shared.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadExistingKeys()
        }
    }
    
    private func loadExistingKeys() {
        for provider in APIProvider.allCases {
            if let key = KeychainManager.shared.retrieve(for: provider) {
                apiKeys[provider] = String(repeating: "•", count: min(key.count, 20))
            }
        }
    }
    
    private func saveApiKey(for provider: APIProvider) {
        guard let key = apiKeys[provider]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty,
              !key.contains("•") else {
            alertMessage = "Please enter a valid API key"
            showingAlert = true
            return
        }
        
        if KeychainManager.shared.save(apiKey: key, for: provider) {
            alertMessage = "\(provider.displayName) API key saved successfully"
            apiKeys[provider] = String(repeating: "•", count: min(key.count, 20))
        } else {
            alertMessage = "Failed to save API key"
        }
        showingAlert = true
    }
    
    private func deleteApiKey(for provider: APIProvider) {
        if KeychainManager.shared.delete(for: provider) {
            alertMessage = "\(provider.displayName) API key deleted"
            apiKeys[provider] = ""
        } else {
            alertMessage = "Failed to delete API key"
        }
        showingAlert = true
    }
}

#Preview {
    SettingsView()
}