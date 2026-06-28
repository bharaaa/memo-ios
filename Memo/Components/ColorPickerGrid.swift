//
//  ColorPickerGrid.swift
//  Memo
//
//  Reusable grid of preset colors for categories and accounts.
//  Colors are passed and returned as hex strings.
//

import SwiftUI

struct ColorPickerGrid: View {
    @Binding var selectedHex: String
    
    // Preset hex colors
    let presetHexColors = [
        // Reds / Pinks
        "#EF4444", "#F43F5E", "#EC4899", "#D946EF",
        // Purples
        "#A855F7", "#8B5CF6", "#6366F1", "#4F46E5",
        // Blues
        "#3B82F6", "#0EA5E9", "#06B6D4", "#0891B2",
        // Greens / Teals
        "#14B8A6", "#10B981", "#22C55E", "#84CC16",
        // Yellows / Oranges
        "#EAB308", "#F59E0B", "#F97316", "#EA580C",
        // Neutrals
        "#64748B", "#71717A", "#737373", "#78716C"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 44, maximum: 60), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(presetHexColors, id: \.self) { hex in
                    Button {
                        withAnimation {
                            selectedHex = hex
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 50, height: 50)
                            
                            if selectedHex.uppercased() == hex.uppercased() {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ColorPickerGrid(selectedHex: .constant("#3B82F6"))
}
