import SwiftUI

/// First-launch screen: pick your country. Everything downstream —
/// currency, formatting, autopay labels, seed data — follows this choice.
struct OnboardingView: View {
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selected: Country = .india

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 70)

                Text("💜")
                    .font(.system(size: 52))
                    .padding(.bottom, 12)

                Text("Renewly")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundColor(.white)

                Text("Never pay for a forgotten\nsubscription again.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.62))
                    .padding(.top, 8)
                    .padding(.bottom, 26)

                Text("Where are you?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Country.allCases) { c in
                        Button { selected = c } label: {
                            VStack(spacing: 6) {
                                Text(c.flag).font(.system(size: 30))
                                Text(c.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(c.currencyCode)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selected == c ? Color(hex: "8B5CF6").opacity(0.35) : Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selected == c ? Color(hex: "A78BFA") : Color.white.opacity(0.09), lineWidth: selected == c ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    countryCode = selected.rawValue
                    NotificationManager.shared.requestAuthorization()
                    hasOnboarded = true
                } label: {
                    Text("Get started →")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF"), Color(hex: "3B82F6")], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(999)
                        .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
    }
}
