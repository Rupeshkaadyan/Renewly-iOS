import SwiftUI
import SwiftData

enum HomeChip: String, CaseIterable {
    case all, trials, autopay

    var label: String {
        switch self {
        case .all:     return "All"
        case .trials:  return "⏳ Trials"
        case .autopay: return "⚡ Autopay"
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Subscription> { !$0.isCancelled },
           sort: [SortDescriptor(\Subscription.nextRenewal)])
    private var subscriptions: [Subscription]
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue

    @State private var search = ""
    @State private var chip: HomeChip = .all
    @State private var sortByPrice = false
    @State private var showForm = false
    @State private var editingSub: Subscription?
    @State private var actionSub: Subscription?
    @State private var showActions = false
    @State private var guideSub: Subscription?
    @State private var showGuide = false
    @State private var showCountryPicker = false
    @State private var animateGradient = false

    private var country: Country { Country(rawValue: countryCode) ?? .india }
    /// Totals only ever count subscriptions in the selected country's
    /// currency — summing across currencies without an FX rate would
    /// produce a meaningless number.
    private var inCurrency: [Subscription] { subscriptions.filter { $0.currencyCode == country.currencyCode } }
    private var totalMonthly: Double { inCurrency.reduce(0) { $0 + $1.monthlyCost } }
    private var trialCount: Int { subscriptions.filter { $0.isTrial }.count }
    private var currencyCodes: Set<String> { Set(subscriptions.map { $0.currencyCode }) }
    private var mixedCurrencies: Bool { currencyCodes.count > 1 }

    private var filtered: [Subscription] {
        var list = subscriptions
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty { list = list.filter { $0.name.lowercased().contains(q) } }
        switch chip {
        case .trials:  list = list.filter { $0.isTrial }
        case .autopay: list = list.filter { $0.autopay }
        case .all:     break
        }
        if sortByPrice {
            // Price order only compares within the same currency — the
            // selected country's currency sorts first.
            let code = country.currencyCode
            list.sort {
                let aLocal = $0.currencyCode == code
                let bLocal = $1.currencyCode == code
                if aLocal != bLocal { return aLocal && !bLocal }
                return $0.monthlyCost > $1.monthlyCost
            }
        } else {
            list.sort { $0.daysLeft < $1.daysLeft }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        spendCard
                        searchBar
                        chipsRow
                        sectionHeader
                        cards
                    }
                    .padding(.bottom, 110)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            editingSub = nil
                            showForm = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(Circle())
                                .shadow(color: Color(hex: "D946EF").opacity(0.5), radius: 16, x: 0, y: 8)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 96)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showForm) {
            SubscriptionFormView(subscription: editingSub, country: country)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView()
        }
        .sheet(isPresented: $showGuide) {
            if let s = guideSub { CancelGuideView(subscription: s) }
        }
        .confirmationDialog("Subscription options", isPresented: $showActions, titleVisibility: .visible) {
            Button("Edit") {
                editingSub = actionSub
                showForm = true
            }
            Button("Cancel subscription") {
                guideSub = actionSub
                showGuide = true
            }
            Button("Delete", role: .destructive) {
                if let s = actionSub { delete(s) }
            }
            Button("Close", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.62))
                Text("Here's your money.")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            Spacer()
            Button { showCountryPicker = true } label: {
                Text(country.flag)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
    }

    // MARK: - Spend card

    private var spendCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("✦ Total monthly spend")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            Text(money(totalMonthly, country: country))
                .font(.system(size: 44, weight: .heavy))
                .foregroundColor(.white)
            Text("≈ \(money(totalMonthly * 12, country: country)) a year")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, mixedCurrencies ? 2 : 8)
            if mixedCurrencies {
                Text("Only \(country.currencyCode) subscriptions counted.")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.bottom, 8)
            }
            HStack(spacing: 8) {
                Text("\(subscriptions.count) active")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(999)
                if trialCount > 0 {
                    Text("⏳ \(trialCount) \(trialCount == 1 ? String(localized: "trial") : String(localized: "trials"))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FDE68A"))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(hex: "FBBF24").opacity(0.25))
                        .cornerRadius(999)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF"), Color(hex: "3B82F6")],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateGradient)
        )
        .cornerRadius(24)
        .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .onAppear { animateGradient = true }
    }

    // MARK: - Search + chips

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.35))
            TextField("Search subscriptions…", text: $search)
                .foregroundColor(.white)
        }
        .padding(13)
        .padding(.horizontal, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.09), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var chipsRow: some View {
        HStack(spacing: 8) {
            ForEach(HomeChip.allCases, id: \.self) { c in
                Button(c.label) { chip = c }
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(chip == c ? .white : .white.opacity(0.62))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(chip == c ? Color(hex: "8B5CF6") : Color.white.opacity(0.06))
                    .cornerRadius(999)
                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.white.opacity(chip == c ? 0 : 0.09), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var sectionHeader: some View {
        HStack {
            Text("Upcoming renewals")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(sortByPrice ? String(localized: "⇅ Price ↓") : String(localized: "⇅ Soonest")) { sortByPrice.toggle() }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.62))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06))
                .cornerRadius(999)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var cards: some View {
        LazyVStack(spacing: 10) {
            ForEach(filtered, id: \.id) { sub in
                SubscriptionRow(subscription: sub) {
                    actionSub = sub
                    showActions = true
                }
            }
            if filtered.isEmpty {
                Text("No matches.\nTry a different search or filter.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, 30)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func delete(_ sub: Subscription) {
        NotificationManager.shared.cancel(for: sub.id)
        context.delete(sub)
        try? context.save()
    }
}
