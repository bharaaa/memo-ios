//
//  SettingsToggleRow.swift
//  Memo
//
//  A native settings row with a Toggle switch.
//

import SwiftUI

struct SettingsToggleRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(iconName: icon, backgroundColor: iconColor)
            
            Toggle(title, isOn: $isOn)
                .foregroundStyle(.primary)
                .tint(Color.memoPrimary)
        }
    }
}
