import Foundation
import UserNotifications

/// Schedules real iOS local notifications: one day before every renewal
/// (or trial end), at 9:00 AM local time. Amounts use each subscription's
/// own currency.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func schedule(for sub: Subscription) {
        cancel(for: sub.id)
        guard !sub.isCancelled else { return }
        let country = Country.from(currencyCode: sub.currencyCode)

        let calendar = Calendar.current
        let renewalDay = calendar.startOfDay(for: sub.nextRenewal)
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: renewalDay) else { return }
        var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        comps.hour = 9
        comps.minute = 0
        guard let fireDate = calendar.date(from: comps), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        if sub.isTrial {
            content.title = String(localized: "Trial ending soon")
            content.body = String(format: String(localized: "trialEndingBody"),
                                  sub.name, money(sub.price, country: country))
        } else {
            content.title = String(localized: "Renewal tomorrow")
            content.body = String(format: String(localized: "renewalTomorrowBody"),
                                  sub.name, money(sub.price, country: country))
        }
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: sub.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancel(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    /// Immediate alert when a subscription's price is edited — price hikes
    /// are the #1 thing rival trackers never warn about.
    func priceChangeAlert(for sub: Subscription, oldPrice: Double, newPrice: Double) {
        let country = Country.from(currencyCode: sub.currencyCode)
        let content = UNMutableNotificationContent()
        let up = newPrice > oldPrice
        content.title = String(localized: "Price changed")
        let fmt = String(localized: "priceChangeBody")
        content.body = String(format: fmt, sub.name,
                              money(oldPrice, country: country),
                              money(newPrice, country: country))
        content.sound = .default
        // Tag it so the Alerts tab can surface it too.
        content.userInfo = ["priceChange": up ? "up" : "down"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "price-\(sub.id.uuidString)-\(Int(Date().timeIntervalSince1970))",
            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
