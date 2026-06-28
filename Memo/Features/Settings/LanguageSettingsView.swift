//
//  LanguageSettingsView.swift
//  Memo
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    
    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        languageManager.currentLanguage = language
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.memoPrimary)
                            }
                        }
                    }
                }
            } footer: {
                if languageManager.currentLanguage == .system {
                    Text(L10n.systemLanguageDescription)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.languageSelection)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
            .environment(LanguageManager.shared)
    }
}
