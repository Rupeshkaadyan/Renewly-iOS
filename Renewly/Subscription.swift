import Foundation
import SwiftData

enum BillingCycle: String, Codable, CaseIterable {
    case monthly, yearly

    var label: String {
        switch self {
        case .monthly: return String(localized: "Monthly")
        case .yearly: return String(localized: "Yearly")
        }
    }
    var short: String { self == .monthly ? "mo" : "yr" }
}

enum Category: String, Codable, CaseIterable, Identifiable {
    case entertainment, music, utilities, productivity, other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .entertainment: return String(localized: "Entertainment")
        case .music:         return String(localized: "Music")
        case .utilities:     return String(localized: "Utilities")
        case .productivity:  return String(localized: "Productivity")
        case .other:         return String(localized: "Other")
        }
    }

    /// Hex without '#', used by Color(hex:).
    var hex: String {
        switch self {
        case .entertainment: return "8B5CF6"
        case .music:         return "22C55E"
        case .utilities:     return "3B82F6"
        case .productivity:  return "F59E0B"
        case .other:         return "94A3B8"
        }
    }
}

/// One recorded price change. Stored as JSON on the subscription because
/// SwiftData has no native array-of-struct support.
struct PriceChange: Codable {
    var date: Date
    var oldPrice: Double
    var newPrice: Double

    var wentUp: Bool { newPrice > oldPrice }
}

@Model
final class Subscription {
    var id: UUID
    var name: String
    var price: Double
    var cycle: BillingCycle
    var nextRenewal: Date
    var category: Category
    var autopay: Bool
    var isTrial: Bool
    var colorHex: String
    var isCancelled: Bool
    var cancelledAt: Date?
    /// The currency the price was entered in (e.g. "INR"). Switching the
    /// app's country never relabels existing prices — each subscription
    /// keeps its own currency.
    var currencyCode: String = "INR"
    /// JSON-encoded price history; nil until the first price edit.
    /// Added after v1 — SwiftData's lightweight migration fills nil.
    var priceHistoryData: Data? = nil

    /// Decoded price history, oldest first.
    var priceHistory: [PriceChange] {
        get {
            guard let data = priceHistoryData,
                  let list = try? JSONDecoder().decode([PriceChange].self, from: data)
            else { return [] }
            return list
        }
        set { priceHistoryData = try? JSONEncoder().encode(newValue) }
    }

    init(name: String,
         price: Double,
         cycle: BillingCycle = .monthly,
         nextRenewal: Date,
         category: Category = .entertainment,
         autopay: Bool = false,
         isTrial: Bool = false,
         colorHex: String = "8B5CF6",
         isCancelled: Bool = false,
         cancelledAt: Date? = nil,
         currencyCode: String = "INR") {
        self.id = UUID()
        self.name = name
        self.price = price
        self.cycle = cycle
        self.nextRenewal = nextRenewal
        self.category = category
        self.autopay = autopay
        self.isTrial = isTrial
        self.colorHex = colorHex
        self.isCancelled = isCancelled
        self.cancelledAt = cancelledAt
        self.currencyCode = currencyCode
    }

    /// Cost normalised to a monthly figure so totals and sorting stay fair.
    var monthlyCost: Double {
        cycle == .yearly ? price / 12 : price
    }

    /// Whole days from today until the renewal date (negative if overdue).
    var daysLeft: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: nextRenewal)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
