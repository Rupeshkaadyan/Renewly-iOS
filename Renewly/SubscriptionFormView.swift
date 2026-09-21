import SwiftUI
import SwiftData

/// Add a new subscription or edit an existing one (nil = add).
/// A new subscription takes the currently selected country's currency;
/// editing never changes a subscription's existing currency.
struct SubscriptionFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription?
    let country: Country

    /// Currency shown in the form: the subscription's own when editing,
    /// the selected country when adding.
    private var displayCountry: Country {
        if let sub = subscription {
            return Country.from(currencyCode: sub.currencyCode)
        }
        return country
    }

    @State private var name: String
    @State private var priceText: String
    @State private var cycle: BillingCycle
    @State private var date: Date
    @State private var category: Category
    @State private var autopay: Bool
    @State private var isTrial: Bool
    @State private var showError = false

    init(subscription: Subscription?, country: Country) {
        self.subscription = subscription
        self.country = country
        _name = State(initialValue: subscription?.name ?? "")
        _priceText = State(initialValue: subscription.map { String($0.price) } ?? "")
        _cycle = State(initialValue: subscription?.cycle ?? .monthly)
        _date = State(initialValue: subscription?.nextRenewal ?? (Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()))
        _category = State(initialValue: subscription?.category ?? .entertainment)
        _autopay = State(initialValue: subscription?.autopay ?? true)
        _isTrial = State(initialValue: subscription?.isTrial ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name — e.g. Netflix", text: $name)
                    HStack {
                        Text(displayCountry.currencySymbol)
                            .foregroundColor(.white.opacity(0.5))
                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Billing") {
                    Picker("Cycle", selection: $cycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { c in
                            Text("\(c.label) · \(displayCountry.currencySymbol)").tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    DatePicker("Renews on", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases) { c in
                            Text(c.label).tag(c)
                        }
                    }
                }

                Section("Options") {
                    Toggle(displayCountry.autopayLabel, isOn: $autopay)
                    Toggle("Free trial", isOn: $isTrial)
                }

                if showError {
                    Text("Give it a name and a price above zero.")
                        .foregroundColor(Color(hex: "F87171"))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AuroraBackground())
            .navigationTitle(subscription == nil ? "Add subscription" : "Edit subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard !cleanName.isEmpty, price > 0 else {
            showError = true
            return
        }

        if let sub = subscription {
            // A price edit is a price change worth remembering — record it
            // so Renewly can warn about hikes later.
            if sub.price != price, sub.price > 0 {
                var history = sub.priceHistory
                history.append(PriceChange(date: Date(), oldPrice: sub.price, newPrice: price))
                sub.priceHistory = history
                NotificationManager.shared.priceChangeAlert(for: sub, oldPrice: sub.price, newPrice: price)
            }
            sub.name = cleanName
            sub.price = price
            sub.cycle = cycle
            sub.nextRenewal = date
            sub.category = category
            sub.autopay = autopay
            sub.isTrial = isTrial
            sub.colorHex = sub.colorHex.isEmpty ? category.hex : sub.colorHex
            NotificationManager.shared.schedule(for: sub)
        } else {
            let sub = Subscription(
                name: cleanName,
                price: price,
                cycle: cycle,
                nextRenewal: date,
                category: category,
                autopay: autopay,
                isTrial: isTrial,
                colorHex: category.hex,
                currencyCode: country.currencyCode
            )
            context.insert(sub)
            NotificationManager.shared.schedule(for: sub)
        }
        try? context.save()
        dismiss()
    }
}
