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
        VStack(alignment: .leading, spacing: 2) {
            Text("\(timeGreeting)\(userName.isEmpty ? "" : ",")")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                
            if !userName.isEmpty {
                Text(userName)
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundStyle(Color.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .memoScreenPadding()
        .padding(.top, 16)
        .padding(.bottom, 24) // Increased breathing room above composer
    }
}
