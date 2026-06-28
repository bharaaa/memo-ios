//
//  SettingsRow.swift
//  Memo
//
//  A native settings row for static display.
//

import SwiftUI

struct SettingsRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    var subtitle: String? = nil
    var value: String? = nil
    
    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(iconName: icon, backgroundColor: iconColor)
            
            Text(title)
                .foregroundStyle(.primary)
            
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
        }
    }
}
