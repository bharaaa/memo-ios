//
//  GreetingSection.swift
//  Memo
//
//  A lightweight, native greeting.
//

import SwiftUI

struct GreetingSection: View {
    let timeGreeting: String
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(timeGreeting)\(userName.isEmpty ? "" : ",")")
                .font(.subheadline)
                .foregroundStyle(.memoSecondaryText)
                
            if !userName.isEmpty {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.memoPrimaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .memoScreenPadding()
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}
