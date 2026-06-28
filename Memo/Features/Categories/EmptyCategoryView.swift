//
//  EmptyCategoryView.swift
//  Memo
//
//  Empty state for the Categories list.
//

import SwiftUI

struct EmptyCategoryView: View {
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.memoTertiaryText)
            
            Text("No Categories Yet")
                .font(.headline)
                .foregroundStyle(.memoPrimaryText)
            
            Text("Create your first category to start organizing your transactions.")
                .font(.subheadline)
                .foregroundStyle(.memoSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onAddTapped) {
                Text("Add Category")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.memoPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
}
