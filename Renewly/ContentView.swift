import SwiftUI
import SwiftData

enum AppTab: Int, CaseIterable {
    case home, alerts, stats, settings

    var label: String {
        switch self {
        case .home:     return "Home"
        case .alerts:   return "Alerts"
        case .stats:    return "Stats"
        case .settings: return "Settings"
        }
    }

    static func fromLaunchArg() -> AppTab? {
        #if DEBUG
        let args = CommandLine.arguments
        for tab in AppTab.allCases {
            if args.contains("-tab-\(tab.label.lowercased())") { return tab }
        }
        #endif
        return nil
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var subscriptions: [Subscription]
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue

    @State private var selectedTab: Int = 0

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
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home.rawValue)
            AlertsView()
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .badge(alertCount)
                .tag(AppTab.alerts.rawValue)
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(AppTab.stats.rawValue)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings.rawValue)
        }
        .tint(Color(hex: "A78BFA"))
        .onAppear {
            seedIfNeeded()
            rollForward()
            if selectedTab == 0, let tab = AppTab.fromLaunchArg() {
                selectedTab = tab.rawValue
            }
        }
    }

    /// First launch: insert starter subscriptions for the chosen country.
    /// When launched with `-seedDemo` we wipe and reseed so screenshots
    /// stay deterministic regardless of prior install state.
    private func seedIfNeeded() {
        #if DEBUG
        let reseed = CommandLine.arguments.contains("-seedDemo")
        #else
        let reseed = false
        #endif
        if reseed {
            for sub in subscriptions { context.delete(sub) }
            try? context.save()
        }
        guard subscriptions.isEmpty || reseed else { return }
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
