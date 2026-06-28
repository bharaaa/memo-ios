//
//  AppearanceSettingsView.swift
//  Memo
//
//  Allows the user to select their preferred appearance (Light, Dark, System).
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    
    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.inline)
            } footer: {
                Text("Choose 'System' to match your device's appearance settings.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
