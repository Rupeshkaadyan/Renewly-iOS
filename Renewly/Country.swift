import Foundation

/// Every country Renewly supports. Picking one drives the currency,
/// number formatting, and the autopay label across the whole app.
enum Country: String, CaseIterable, Identifiable {
    case india, usa, uk, eurozone, japan, canada, australia, uae, singapore

    var id: String { rawValue }

    var name: String {
        switch self {
        case .india:     return String(localized: "India")
        case .usa:       return String(localized: "United States")
        case .uk:        return String(localized: "United Kingdom")
        case .eurozone:  return String(localized: "Eurozone")
        case .japan:     return String(localized: "Japan")
        case .canada:    return String(localized: "Canada")
        case .australia: return String(localized: "Australia")
        case .uae:       return String(localized: "UAE")
        case .singapore: return String(localized: "Singapore")
        }
    }

    var flag: String {
        switch self {
        case .india:     return "🇮🇳"
        case .usa:       return "🇺🇸"
        case .uk:        return "🇬🇧"
        case .eurozone:  return "🇪🇺"
        case .japan:     return "🇯🇵"
        case .canada:    return "🇨🇦"
        case .australia: return "🇦🇺"
        case .uae:       return "🇦🇪"
        case .singapore: return "🇸🇬"
        }
    }

    var currencyCode: String {
        switch self {
        case .india:     return "INR"
        case .usa:       return "USD"
        case .uk:        return "GBP"
        case .eurozone:  return "EUR"
        case .japan:     return "JPY"
        case .canada:    return "CAD"
        case .australia: return "AUD"
        case .uae:       return "AED"
        case .singapore: return "SGD"
        }
    }

    var currencySymbol: String {
        switch self {
        case .india:     return "₹"
        case .usa:       return "$"
        case .uk:        return "£"
        case .eurozone:  return "€"
        case .japan:     return "¥"
        case .canada:    return "$"
        case .australia: return "$"
        case .uae:       return "د.إ"
        case .singapore: return "$"
        }
    }

    /// Locale drives digit grouping (India gets lakh/crore grouping) and symbol placement.
    var localeIdentifier: String {
        switch self {
        case .india:     return "en_IN"
        case .usa:       return "en_US"
        case .uk:        return "en_GB"
        case .eurozone:  return "de_DE"
        case .japan:     return "ja_JP"
        case .canada:    return "en_CA"
        case .australia: return "en_AU"
        case .uae:       return "ar_AE"
        case .singapore: return "en_SG"
        }
    }

    /// India gets the UPI-specific label; everywhere else it's plain Autopay.
    var autopayLabel: String {
        self == .india ? String(localized: "UPI Autopay") : String(localized: "Autopay")
    }

    /// Look up the country for a stored currency code (each subscription
    /// remembers its own). Falls back to India for unknown codes.
    static func from(currencyCode: String) -> Country {
        allCases.first { $0.currencyCode == currencyCode } ?? .india
    }
}

/// Formats an amount in the country's currency, e.g. ₹1,00,000 / $1,299 / €1.299.
func money(_ value: Double, country: Country) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = country.currencyCode
    formatter.locale = Locale(identifier: country.localeIdentifier)
    let isWhole = value.truncatingRemainder(dividingBy: 1) == 0
    formatter.minimumFractionDigits = isWhole ? 0 : 2
    formatter.maximumFractionDigits = isWhole ? 0 : 2
    return formatter.string(from: NSNumber(value: value)) ?? "\(country.currencySymbol)\(Int(value))"
}

/// Formats an amount in an explicit currency code — used for subscriptions
/// that keep the currency they were entered in.
func money(_ value: Double, currencyCode: String) -> String {
    money(value, country: Country.from(currencyCode: currencyCode))
}
