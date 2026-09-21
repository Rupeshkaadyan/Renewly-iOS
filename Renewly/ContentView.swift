import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var subscriptions: [Subscription]
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue

    private var country: Country { Country(rawValue: countryCode) ?? .india }

    /// Trials ending within 3 days + renewals in the next 7 days.
    private var alertCount: Int {
        subscriptions.filter { sub in
            guard !sub.isCancelled else { return false }
            if sub.isTrial { return sub.daysLeft <= 3 }
            return sub.daysLeft >= 0 && sub.daysLeft <= 7
        }.count
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            AlertsView()
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .badge(alertCount)
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(hex: "A78BFA"))
        .onAppear {
            seedIfNeeded()
            rollForward()
        }
    }

    /// First launch: insert starter subscriptions for the chosen country.
    private func seedIfNeeded() {
        guard subscriptions.isEmpty else { return }
        for sub in SeedData.make(for: country) {
            context.insert(sub)
            NotificationManager.shared.schedule(for: sub)
        }
        try? context.save()
    }

    /// Push overdue renewals forward so dates never go stale.
    private func rollForward() {
        let today = Calendar.current.startOfDay(for: Date())
        var changed = false
        for sub in subscriptions where !sub.isCancelled {
            var d = Calendar.current.startOfDay(for: sub.nextRenewal)
            var guardCount = 0
            var moved = false
            while d < today && guardCount < 120 {
                let comp: Calendar.Component = sub.cycle == .yearly ? .year : .month
                if let next = Calendar.current.date(byAdding: comp, value: 1, to: d) {
                    d = next
                    moved = true
                }
                guardCount += 1
            }
            if moved {
                sub.nextRenewal = d
                NotificationManager.shared.schedule(for: sub)
                changed = true
            }
        }
        if changed {
            try? context.save()
        }
    }
}
