//
//  SettingsIcon.swift
//  Memo
//
//  A native Apple Settings-style icon (rounded square with a colored background).
//

import SwiftUI

struct SettingsIcon: View {
    let iconName: String
    let backgroundColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(backgroundColor)
                .frame(width: 28, height: 28)
            
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white)
        }
    }
}
