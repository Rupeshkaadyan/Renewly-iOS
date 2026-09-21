import SwiftUI

/// Change the active country. Each subscription keeps the currency it was
/// entered in; new subscriptions use the newly selected currency.
struct CountryPickerView: View {
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                List {
                    Section {
                        ForEach(Country.allCases) { c in
                            Button {
                                countryCode = c.rawValue
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Text(c.flag).font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("\(c.currencyCode) · \(c.currencySymbol)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    if c.rawValue == countryCode {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(hex: "A78BFA"))
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .listRowBackground(Color.white.opacity(0.04))
                        }
                    } footer: {
                        Text("Each subscription keeps the currency it was entered in. New ones use the newly picked currency.")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 12))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
