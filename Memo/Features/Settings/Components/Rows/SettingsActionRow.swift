//
//  SettingsActionRow.swift
//  Memo
//
//  A native settings row that performs an action (like presenting a modal).
//

import SwiftUI

struct SettingsActionRow: View {
    let title: LocalizedStringKey
    let icon: String
    let iconColor: Color
    var subtitle: String? = nil
    var value: String? = nil
    var showChevron: Bool = true
    var role: ButtonRole? = nil
    let action: () -> Void
    
    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 14) {
                SettingsIcon(iconName: icon, backgroundColor: iconColor)
                
                Text(title)
                    .foregroundStyle(role == .destructive ? .red : .primary)
                
                Spacer()
                
                if let subtitle {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                
                if let value {
                    Text(value)
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
