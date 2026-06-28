import Foundation

/// Centralized formatters to avoid expensive re-instantiation.
final class Formatters {
    static let shared = Formatters()
    
    private var currencyFormatters = [String: NumberFormatter]()
    private let queue = DispatchQueue(label: "com.memo.formatters")
    
    private init() {}
    
    /// Returns a cached NumberFormatter configured for the given currency code.
    func currencyFormatter(for currencyCode: String) -> NumberFormatter {
        queue.sync {
            if let formatter = currencyFormatters[currencyCode] {
                return formatter
            }
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.maximumFractionDigits = currencyCode == "IDR" || currencyCode == "JPY" ? 0 : 2
            
            currencyFormatters[currencyCode] = formatter
            return formatter
        }
    }
    
    /// A shared decimal parser
    let decimalParser: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
}
