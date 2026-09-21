import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allSubs: [Subscription]
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue
    @State private var confirmRemoveID: UUID?

    private var country: Country { Country(rawValue: countryCode) ?? .india }
    private var active: [Subscription] { allSubs.filter { !$0.isCancelled } }
    private var cancelled: [Subscription] { allSubs.filter { $0.isCancelled } }
    /// Aggregates only count subscriptions in the selected country's
    /// currency — summing across currencies without an FX rate would be
    /// a meaningless number.
    private var inCurrency: [Subscription] { active.filter { $0.currencyCode == country.currencyCode } }
    private var totalMonthly: Double { inCurrency.reduce(0) { $0 + $1.monthlyCost } }
    private var totalSaved: Double { cancelled.filter { $0.currencyCode == country.currencyCode }.reduce(0) { $0 + $1.monthlyCost } }
    private var currencyCodes: Set<String> { Set(active.map { $0.currencyCode }) }
    private var mixedCurrencies: Bool { currencyCodes.count > 1 }

    private struct CatSpend: Identifiable {
        let id = UUID()
        let category: Category
        let total: Double
    }

    private struct DupGroup: Identifiable {
        let id: String
        let category: Category
        let subs: [Subscription]
    }

    private var spends: [CatSpend] {
        Dictionary(grouping: inCurrency, by: { $0.category })
            .map { CatSpend(category: $0.key, total: $0.value.reduce(0) { $0 + $1.monthlyCost }) }
            .sorted { $0.total > $1.total }
    }

    private var biggest: Subscription? {
        inCurrency.max(by: { $0.monthlyCost < $1.monthlyCost })
    }

    /// Monthly-billing subscriptions, priciest first — candidates for an
    /// annual plan. We never invent the annual price; we nudge the user
    /// to check the provider's pricing page.
    private var annualNudges: [Subscription] {
        Array(inCurrency.filter { $0.cycle == .monthly }
            .sorted { $0.monthlyCost > $1.monthlyCost }
            .prefix(2))
    }

    /// Categories with 2+ active subscriptions — possible overlap.
    private var duplicateGroups: [DupGroup] {
        Dictionary(grouping: inCurrency, by: { $0.category })
            .filter { $0.value.count > 1 }
            .map { DupGroup(id: $0.key.rawValue, category: $0.key, subs: $0.value) }
            .sorted { $0.subs.count > $1.subs.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Stats")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 56)

                        savingsCard
                        donutSection
                        legend
                        projectionSection
                        insightCard
                        smartInsights
                        cancelledSection
                    }
                    .padding(.bottom, 110)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Savings

    private var savingsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("💰 Saved by cancelling")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text("\(money(totalSaved, country: country))/mo")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.white)
            Text("That's \(money(totalSaved * 12, country: country)) a year back in your pocket.\(mixedCurrencies ? String(localized: " Only \(country.currencyCode) cancellations counted.") : "")")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "F97316")], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(24)
        .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    // MARK: - Donut

    private var donutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Where it goes")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            if spends.isEmpty {
                Text("Add a subscription to see the breakdown.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            } else {
                ZStack {
                    Chart(spends) { s in
                        SectorMark(
                            angle: .value("Spend", s.total),
                            innerRadius: .ratio(0.62),
                            angularInset: 2.5
                        )
                        .foregroundStyle(by: .value("Category", s.category.label))
                    }
                    .chartForegroundStyleScale(
                        domain: Category.allCases.map(\.label),
                        range: Category.allCases.map { Color(hex: $0.hex) }
                    )
                    .chartLegend(.hidden)
                    .frame(height: 220)

                    VStack(spacing: 2) {
                        Text(money(totalMonthly, country: country))
                            .font(.system(size: 27, weight: .heavy))
                            .foregroundColor(.white)
                        if mixedCurrencies {
                            Text("This month · \(country.currencyCode) only")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.62))
                        } else {
                            Text("This month")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.62))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
        }
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118))], spacing: 8) {
            ForEach(spends) { s in
                let pct = totalMonthly > 0 ? Int((s.total / totalMonthly * 100).rounded()) : 0
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: s.category.hex))
                        .frame(width: 9, height: 9)
                    Text("\(s.category.label) · \(pct)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.62))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(999)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Projection

    /// An honest forward projection: your current monthly total, carried
    /// across the next 6 months. No invented history.
    private var projectionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Projected spend")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            let months = next6Months()
            let maxV = max(totalMonthly, 1)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(i == 0
                                ? LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "F97316")], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "3B82F6")], startPoint: .top, endPoint: .bottom))
                            .frame(height: max(8, CGFloat(totalMonthly / maxV) * 130))
                        Text(months[i])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 172)
            .padding(.horizontal, 22)
            .padding(.top, 12)

            Text("Based on your current \(money(totalMonthly, country: country))/mo\(mixedCurrencies ? String(localized: " (\(country.currencyCode) only)") : "") — no history invented.")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
    }

    private func next6Months() -> [String] {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return (0..<6).map { i in
            f.string(from: Calendar.current.date(byAdding: .month, value: i, to: Date()) ?? Date())
        }
    }

    // MARK: - Insight

    private var insightCard: some View {
        Group {
            if let b = biggest {
                VStack(alignment: .leading, spacing: 6) {
                    Text("💡 Insight")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your biggest spend is ")
                        .foregroundColor(.white.opacity(0.62))
                    + Text(b.name).bold().foregroundColor(.white)
                    + Text(" at \(money(b.monthlyCost, currencyCode: b.currencyCode))/month. That's \(Int((b.monthlyCost / max(totalMonthly, 1) * 100).rounded()))% of your total — worth a second look.")
                        .foregroundColor(.white.opacity(0.62))
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.white.opacity(0.045))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }
        }
    }

    // MARK: - Smart insights

    /// What rival trackers don't say: annual-plan nudges (without inventing
    /// prices) and overlap detection across categories.
    private var smartInsights: some View {
        Group {
            if !annualNudges.isEmpty || !duplicateGroups.isEmpty {
                VStack(spacing: 12) {
                    ForEach(annualNudges, id: \.id) { sub in
                        insightCardView(
                            title: String(localized: "Annual could be cheaper"),
                            body: "\(sub.name) on monthly billing costs \(money(sub.monthlyCost * 12, country: country)) a year. Check if \(sub.name) offers an annual plan and compare the real prices.",
                            tint: "A78BFA"
                        )
                    }
                    ForEach(duplicateGroups) { group in
                        let names = group.subs.map { $0.name }.joined(separator: ", ")
                        insightCardView(
                            title: String(localized: "Possible overlap"),
                            body: "You have \(group.subs.count) \(group.category.label.lowercased()) subscriptions (\(names)). Do you need them all?",
                            tint: "FBBF24"
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }
        }
    }

    private func insightCardView(title: String, body: LocalizedStringKey, tint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("💡 \(title)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(body)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.045))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: tint).opacity(0.25), lineWidth: 1))
    }

    // MARK: - Cancelled

    private var cancelledSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Cancelled (\(cancelled.count))")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            if cancelled.isEmpty {
                Text("Nothing cancelled yet. When you cancel one,\nits savings show up here.")
                    .font(.system(size: 13.5))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(cancelled, id: \.id) { sub in
                        HStack(spacing: 13) {
                            SvcIcon(name: sub.name, hex: sub.colorHex)
                                .opacity(0.55)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white.opacity(0.75))
                                Text("Saving \(money(sub.monthlyCost, currencyCode: sub.currencyCode))/mo")
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(Color(hex: "FBBF24"))
                            }
                            Spacer()
                            Button("Restore") {
                                sub.isCancelled = false
                                sub.cancelledAt = nil
                                NotificationManager.shared.schedule(for: sub)
                                try? context.save()
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Color(hex: "8B5CF6"))
                            .cornerRadius(999)

                            Button(confirmRemoveID == sub.id ? "Sure?" : "Remove") {
                                if confirmRemoveID == sub.id {
                                    NotificationManager.shared.cancel(for: sub.id)
                                    context.delete(sub)
                                    try? context.save()
                                    confirmRemoveID = nil
                                } else {
                                    confirmRemoveID = sub.id
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(confirmRemoveID == sub.id ? .white : Color(hex: "F87171"))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(confirmRemoveID == sub.id ? Color(hex: "EF4444") : Color(hex: "F87171").opacity(0.12))
                            .cornerRadius(999)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
    }
}
