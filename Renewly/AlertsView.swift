import SwiftUI
import SwiftData

struct AlertsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Subscription> { !$0.isCancelled },
           sort: [SortDescriptor(\Subscription.nextRenewal)])
    private var subscriptions: [Subscription]
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue

    @State private var guideSub: Subscription?
    @State private var showGuide = false
    @State private var editingSub: Subscription?
    @State private var showForm = false

    private var country: Country { Country(rawValue: countryCode) ?? .india }

    private var trials: [Subscription] {
        subscriptions.filter { $0.isTrial && $0.daysLeft <= 3 }
    }

    private var soon: [Subscription] {
        subscriptions
            .filter { !$0.isTrial && $0.daysLeft >= 0 && $0.daysLeft <= 7 }
            .sorted { $0.daysLeft < $1.daysLeft }
    }

    /// Subscriptions whose price was edited, newest change first.
    /// Price hikes are the #1 thing rival trackers never warn about.
    private var priceChanges: [Subscription] {
        subscriptions.filter { !$0.priceHistory.isEmpty }
            .sorted { ($0.priceHistory.last?.date ?? .distantPast) > ($1.priceHistory.last?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Alerts")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 56)

                        if trials.isEmpty && soon.isEmpty && priceChanges.isEmpty {
                            emptyState
                        } else {
                            trialCards
                            priceCards
                            reminderSection
                        }
                    }
                    .padding(.bottom, 110)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showGuide) {
            if let s = guideSub { CancelGuideView(subscription: s) }
        }
        .sheet(isPresented: $showForm) {
            SubscriptionFormView(subscription: editingSub, country: country)
        }
    }

    // MARK: - Trials

    private var trialCards: some View {
        ForEach(trials, id: \.id) { sub in
            let daysText: String = {
                let n = sub.daysLeft
                if n <= 0 { return String(localized: "today") }
                if n == 1 { return String(localized: "tomorrow") }
                return String(format: String(localized: "inDays"), "\(n)")
            }()

            return VStack(alignment: .leading, spacing: 10) {
                Text("⚠️")
                    .font(.system(size: 30))
                Text("Trial ending soon")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
                (Text("Your ")
                    .foregroundColor(.white.opacity(0.62))
                + Text(sub.name).bold().foregroundColor(.white)
                + Text(" trial ends \(daysText). Cancel now or you'll be charged ")
                    .foregroundColor(.white.opacity(0.62))
                + Text(money(sub.price, currencyCode: sub.currencyCode)).bold().foregroundColor(.white))
                    .font(.system(size: 14))

                Button {
                    guideSub = sub
                    showGuide = true
                } label: {
                    Text("Show me how to cancel →")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "FBBF24"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "FBBF24").opacity(0.12))
                        .cornerRadius(999)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color(hex: "FBBF24").opacity(0.4), lineWidth: 1))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(colors: [Color(hex: "FBBF24").opacity(0.22), Color(hex: "FBBF24").opacity(0.05)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(22)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "FBBF24").opacity(0.35), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    // MARK: - Price changes

    private var priceCards: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !priceChanges.isEmpty {
                Text("Price changes")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, trials.isEmpty ? 14 : 22)

                LazyVStack(spacing: 10) {
                    ForEach(priceChanges, id: \.id) { sub in
                        if let change = sub.priceHistory.last {
                            let c = Country.from(currencyCode: sub.currencyCode)
                            let pct: Int = change.oldPrice > 0
                                ? Int(((change.newPrice - change.oldPrice) / change.oldPrice * 100).rounded())
                                : 0
                            HStack(spacing: 13) {
                                Text(change.wentUp ? "📈" : "📉")
                                    .font(.system(size: 26))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(sub.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(money(change.oldPrice, country: c)) → \(money(change.newPrice, country: c))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(change.wentUp ? Color(hex: "F87171") : Color(hex: "34D399"))
                                    Text("\(shortDate(change.date)) · \(pct >= 0 ? "+" : "")\(pct)%")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.045))
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Reminders

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Upcoming charges")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, trials.isEmpty && priceChanges.isEmpty ? 14 : 22)

            LazyVStack(spacing: 10) {
                ForEach(soon, id: \.id) { sub in
                    SubscriptionRow(subscription: sub) {
                        editingSub = sub
                        showForm = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("🔕")
                .font(.system(size: 44))
                .padding(.top, 60)
            Text("All quiet")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
            Text("No trials ending or renewals due\nin the next 7 days.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
