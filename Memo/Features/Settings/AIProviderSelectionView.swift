//
//  AIProviderSelectionView.swift
//  Memo
//
//  A native settings screen to explicitly choose which AI provider
//  handles transaction parsing.
//

import SwiftUI
import FoundationModels

struct AIProviderSelectionView: View {
    @AppStorage("selectedAIProvider") private var selectedProvider: AIProviderType = .appleFoundation
    
    // External API Configuration
    @State private var openAIBaseURL = UserDefaults.standard.string(forKey: "openai_base_url") ?? "https://api.openai.com/v1"
    @State private var openAIModel = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
    @State private var openAIKey = KeychainService.shared.loadString(forKey: "openai_api_key") ?? ""
    
    // UI State
    @State private var testingConnection = false
    @State private var connectionResult: ConnectionResult?
    
    enum ConnectionResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(AIProviderType.allCases) { provider in
                    Button {
                        withAnimation {
                            selectedProvider = provider
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(provider.title)
                                    .foregroundStyle(.primary)
                                Text(provider.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            if selectedProvider == provider {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("Select the AI engine used to parse your natural language transactions.")
            }
            
            if selectedProvider == .appleFoundation {
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        if SystemLanguageModel.default.isAvailable {
                            Text("Available")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not Available")
                                .foregroundStyle(.red)
                        }
                    }
                } footer: {
                    if !SystemLanguageModel.default.isAvailable {
                        Text("Apple Intelligence is not available on this device. You can continue using Memo with an External API provider.")
                    }
                }
            } else if selectedProvider == .externalAPI {
                Section("Configuration") {
                    HStack {
                        Text("Endpoint")
                        Spacer()
                        TextField("https://api.openai.com/v1", text: $openAIBaseURL)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundStyle(.secondary)
                            .onChange(of: openAIBaseURL) { _, v in
                                UserDefaults.standard.set(v, forKey: "openai_base_url")
                            }
                    }
                    
                    HStack {
                        Text("API Key")
                        Spacer()
                        SecureField("sk-...", text: $openAIKey)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundStyle(.secondary)
                            .onChange(of: openAIKey) { _, v in
                                KeychainService.shared.saveString(v, forKey: "openai_api_key")
                            }
                    }
                    
                    HStack {
                        Text("Model")
                        Spacer()
                        TextField("gpt-4o-mini", text: $openAIModel)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundStyle(.secondary)
                            .onChange(of: openAIModel) { _, v in
                                UserDefaults.standard.set(v, forKey: "openai_model")
                            }
                    }
                }
                
                Section {
                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if testingConnection {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(testingConnection || openAIKey.isEmpty)
                    
                    if let result = connectionResult {
                        switch result {
                        case .success:
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Connected successfully")
                            }
                        case .failure(let error):
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("AI Provider")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func testConnection() {
        testingConnection = true
        connectionResult = nil
        
        Task {
            let provider = OpenAICompatibleProvider()
            do {
                _ = try await provider.parse(input: "Coffee 50")
                connectionResult = .success
            } catch {
                connectionResult = .failure(error.localizedDescription)
            }
            testingConnection = false
        }
    }
}

#Preview {
    NavigationStack {
        AIProviderSelectionView()
    }
}
