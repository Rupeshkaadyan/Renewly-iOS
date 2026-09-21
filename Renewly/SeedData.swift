import Foundation

/// Starter subscriptions per country so the app feels alive on first launch.
/// Dates are relative to today, so the demo is always fresh. Every starter
/// is stamped with its country's currency code.
enum SeedData {
    static func make(for country: Country) -> [Subscription] {
        func days(_ n: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: n, to: Date()) ?? Date()
        }
        let subs: [Subscription]
        switch country {
        case .india:
            subs = [
                Subscription(name: "JioHotstar", price: 149, nextRenewal: days(3), category: .entertainment, autopay: true, colorHex: "5B2EE5"),
                Subscription(name: "Spotify", price: 119, nextRenewal: days(12), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 159, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 75, nextRenewal: days(9), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .usa:
            subs = [
                Subscription(name: "Netflix", price: 15.49, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 11.99, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 13.99, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 0.99, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .uk:
            subs = [
                Subscription(name: "Netflix", price: 10.99, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 11.99, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 12.99, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 0.99, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .eurozone:
            subs = [
                Subscription(name: "Netflix", price: 13.99, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 11.99, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 13.99, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 0.99, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .japan:
            subs = [
                Subscription(name: "Netflix", price: 1490, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 980, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 1280, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 130, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .canada:
            subs = [
                Subscription(name: "Netflix", price: 16.99, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 11.99, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 13.99, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 1.29, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .australia:
            subs = [
                Subscription(name: "Netflix", price: 18.99, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 12.99, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 16.99, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 1.49, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .uae:
            subs = [
                Subscription(name: "Netflix", price: 29.99, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 19.99, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 23.99, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 3.69, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        case .singapore:
            subs = [
                Subscription(name: "Netflix", price: 13.98, nextRenewal: days(4), category: .entertainment, autopay: true, colorHex: "E50914"),
                Subscription(name: "Spotify", price: 9.90, nextRenewal: days(11), category: .music, autopay: true, colorHex: "1DB954"),
                Subscription(name: "YouTube Premium", price: 13.98, nextRenewal: days(1), category: .entertainment, isTrial: true, colorHex: "FF0000"),
                Subscription(name: "iCloud+ 50GB", price: 1.28, nextRenewal: days(8), category: .utilities, autopay: true, colorHex: "3B82F6")
            ]
        }
        subs.forEach { $0.currencyCode = country.currencyCode }
        return subs
    }
}
