import SwiftUI

struct GreetingSection: View {
    let greeting: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.memoLargeTitle)
                .foregroundStyle(.memoPrimaryText)
                
            Text("What do you remember spending today?")
                .font(.memoSubheadline)
                .foregroundStyle(.memoSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }
}
