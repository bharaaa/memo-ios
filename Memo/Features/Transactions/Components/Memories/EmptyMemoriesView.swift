//
//  EmptyMemoriesView.swift
//  Memo
//
//  A calm, beautifully styled empty state for the Memories screen.
//

import SwiftUI

struct EmptyMemoriesView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .padding(.bottom, 8)
            
            Text("Nothing remembered yet.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary)
            
            Text("Try typing an expense like:\n\"Coffee 35k\"")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Button {
                action()
            } label: {
                Text("Add Memory")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.memoPrimary)
                    .clipShape(Capsule())
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}
