//
//  IconPickerView.swift
//  Memo
//
//  Reusable grid of SF Symbols for categories and accounts.
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    
    // Curated list of finance-relevant icons
    let icons = [
        // Finance & Payment
        "banknote.fill", "creditcard.fill", "building.columns.fill", "dollarsign.circle.fill",
        "bitcoinsign.circle.fill", "yensign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
        
        // Food & Drink
        "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill", "wineglass.fill",
        "carrot.fill", "birthday.cake.fill", "bag.fill", "cart.fill",
        
        // Transport
        "car.fill", "bus.fill", "tram.fill", "airplane",
        "bicycle", "fuelpump.fill", "train.side.front.car", "map.fill",
        
        // Home & Utilities
        "house.fill", "lightbulb.fill", "drop.fill", "flame.fill",
        "wifi", "tv.fill", "sofa.fill", "hammer.fill",
        
        // Personal & Entertainment
        "figure.run", "heart.fill", "cross.case.fill", "pills.fill",
        "gamecontroller.fill", "ticket.fill", "music.note", "book.fill",
        
        // General
        "gift.fill", "briefcase.fill", "graduationcap.fill", "star.fill",
        "tag.fill", "folder.fill", "paperplane.fill", "archivebox.fill"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 44, maximum: 60), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        withAnimation {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? Color.memoPrimary : Color.memoSecondaryBackground)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedIcon == icon ? .white : .memoPrimaryText)
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
    IconPickerView(selectedIcon: .constant("banknote.fill"))
}
