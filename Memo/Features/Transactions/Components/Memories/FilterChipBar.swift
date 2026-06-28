//
//  FilterChipBar.swift
//  Memo
//

import SwiftUI

struct FilterChipBar: View {
    @Binding var activeFilters: Set<MemoryFilter>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MemoryFilter.allCases) { filter in
                    let isSelected = activeFilters.contains(filter)
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if isSelected {
                                activeFilters.remove(filter)
                            } else {
                                activeFilters.insert(filter)
                            }
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .medium : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isSelected ? Color.memoPrimary.opacity(0.15) : Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(isSelected ? Color.memoPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? Color.memoPrimary : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
