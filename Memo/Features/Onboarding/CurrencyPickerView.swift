//
//  CurrencyPickerView.swift
//  Memo
//
//  Searchable currency selection list used during onboarding.
//  Prominently lists popular currencies first, then all ISO 4217 codes.
//

import SwiftUI

struct CurrencyPickerView: View {

    @Binding var selected: String
    @State private var searchText = ""

    // Prioritised currencies shown at the top
    private let featured: [CurrencyOption] = [
        .init(code: "IDR", name: "Indonesian Rupiah",  flag: "🇮🇩"),
        .init(code: "USD", name: "US Dollar",          flag: "🇺🇸"),
        .init(code: "EUR", name: "Euro",               flag: "🇪🇺"),
        .init(code: "GBP", name: "British Pound",      flag: "🇬🇧"),
        .init(code: "JPY", name: "Japanese Yen",       flag: "🇯🇵"),
        .init(code: "SGD", name: "Singapore Dollar",   flag: "🇸🇬"),
        .init(code: "MYR", name: "Malaysian Ringgit",  flag: "🇲🇾"),
        .init(code: "AUD", name: "Australian Dollar",  flag: "🇦🇺"),
        .init(code: "KRW", name: "South Korean Won",   flag: "🇰🇷"),
        .init(code: "CNY", name: "Chinese Yuan",       flag: "🇨🇳"),
        .init(code: "INR", name: "Indian Rupee",       flag: "🇮🇳"),
        .init(code: "THB", name: "Thai Baht",          flag: "🇹🇭"),
        .init(code: "PHP", name: "Philippine Peso",    flag: "🇵🇭"),
        .init(code: "VND", name: "Vietnamese Dong",    flag: "🇻🇳"),
        .init(code: "HKD", name: "Hong Kong Dollar",   flag: "🇭🇰"),
        .init(code: "CAD", name: "Canadian Dollar",    flag: "🇨🇦"),
        .init(code: "CHF", name: "Swiss Franc",        flag: "🇨🇭"),
        .init(code: "BRL", name: "Brazilian Real",     flag: "🇧🇷"),
        .init(code: "SAR", name: "Saudi Riyal",        flag: "🇸🇦"),
        .init(code: "AED", name: "UAE Dirham",         flag: "🇦🇪"),
    ]

    private var filtered: [CurrencyOption] {
        guard !searchText.isEmpty else { return featured }
        let q = searchText.lowercased()
        return featured.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.4))
                TextField("Search currency", text: $searchText)
                    .foregroundStyle(.white)
                    .tint(.memoAccent)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.08))
            }
            .padding(.bottom, 8)

            // Currency list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { option in
                        currencyRow(option)
                        if option != filtered.last {
                            Divider().background(.white.opacity(0.08))
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.06))
                }
            }
            .frame(maxHeight: 300)
        }
    }

    private func currencyRow(_ option: CurrencyOption) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selected = option.code
            }
        } label: {
            HStack {
                Text(option.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.code)
                        .font(.memoHeadline)
                        .foregroundStyle(.white)
                    Text(option.name)
                        .font(.memoCaption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                if selected == option.code {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.memoAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(selected == option.code ? Color.white.opacity(0.05) : Color.clear)
    }
}

// MARK: - Model

struct CurrencyOption: Identifiable, Equatable {
    let code: String
    let name: String
    let flag: String
    var id: String { code }
}

#Preview {
    CurrencyPickerView(selected: .constant("IDR"))
        .padding()
        .background(Color(hue: 0.67, saturation: 0.6, brightness: 0.15))
        .preferredColorScheme(.dark)
}
