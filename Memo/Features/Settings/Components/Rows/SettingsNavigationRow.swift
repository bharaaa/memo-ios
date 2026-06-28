//
//  SettingsNavigationRow.swift
//  Memo
//
//  A native navigation row in Settings.
//

import SwiftUI

struct SettingsNavigationRow<Destination: Hashable>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var subtitle: String? = nil
    let destination: Destination
    
    var body: some View {
        NavigationLink(value: destination) {
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
            }
        }
    }
}
