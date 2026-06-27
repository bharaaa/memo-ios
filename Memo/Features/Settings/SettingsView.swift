//
//  SettingsView.swift
//  Memo
//

import SwiftUI

struct SettingsView: View {

    @Environment(AppContainer.self) private var appContainer
    @State private var openAIKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    @State private var openAIBaseURL = UserDefaults.standard.string(forKey: "openai_base_url") ?? "https://api.openai.com/v1"
    @State private var openAIModel = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
    @State private var showCurrencyPicker = false
    @State private var providerStatus: [String: Bool] = [:]
    @AppStorage("preferredCurrencyCode") private var preferredCurrency = "IDR"
    @AppStorage("userName") private var userName = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: Profile
                Section("Profile") {
                    HStack {
                        Label("Name", systemImage: "person.circle")
                        Spacer()
                        TextField("Your name", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.memoSecondaryText)
                    }

                    Button {
                        showCurrencyPicker = true
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle")
                                .foregroundStyle(.memoPrimaryText)
                            Spacer()
                            Text(preferredCurrency)
                                .foregroundStyle(.memoSecondaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.memoTertiaryText)
                        }
                    }
                }

                // MARK: AI Provider
                Section {
                    HStack {
                        Label("API Key", systemImage: "key.fill")
                        Spacer()
                        SecureField("sk-...", text: $openAIKey)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.memoSecondaryText)
                            .onChange(of: openAIKey) { _, v in
                                UserDefaults.standard.set(v, forKey: "openai_api_key")
                            }
                    }

                    HStack {
                        Label("Base URL", systemImage: "network")
                        Spacer()
                        TextField("https://...", text: $openAIBaseURL)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.memoSecondaryText)
                            .onChange(of: openAIBaseURL) { _, v in
                                UserDefaults.standard.set(v, forKey: "openai_base_url")
                            }
                    }

                    HStack {
                        Label("Model", systemImage: "cpu")
                        Spacer()
                        TextField("gpt-4o-mini", text: $openAIModel)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.memoSecondaryText)
                            .onChange(of: openAIModel) { _, v in
                                UserDefaults.standard.set(v, forKey: "openai_model")
                            }
                    }
                } header: {
                    Text("OpenAI Fallback")
                } footer: {
                    Text("Used when Apple Intelligence is not available. Compatible with OpenAI, Mistral, and Ollama.")
                }

                // MARK: Provider Status
                if !providerStatus.isEmpty {
                    Section("AI Providers") {
                        ForEach(providerStatus.sorted(by: { $0.key < $1.key }), id: \.key) { name, available in
                            HStack {
                                Label(
                                    name.replacingOccurrences(of: "_", with: " ").capitalized,
                                    systemImage: available ? "checkmark.circle.fill" : "xmark.circle.fill"
                                )
                                .foregroundStyle(available ? .memoIncome : .memoSecondaryText)
                                Spacer()
                                Text(available ? "Available" : "Unavailable")
                                    .font(.memoCaption)
                                    .foregroundStyle(.memoSecondaryText)
                            }
                        }
                    }
                }

                // MARK: About
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Source & Privacy", systemImage: "lock.shield")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadProviderStatus() }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            NavigationStack {
                CurrencyPickerView(selected: $preferredCurrency)
                    .padding()
                    .navigationTitle("Currency")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showCurrencyPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func loadProviderStatus() async {
        providerStatus = await appContainer.memoService.providerStatus()
    }
}

#Preview {
    SettingsView()
        .environment(AppContainer())
}
