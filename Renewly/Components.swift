import SwiftUI

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(cleaned, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

// MARK: - Aurora background

/// Deep-navy backdrop with soft violet/blue/fuchsia glows, shared by every screen.
struct AuroraBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "0B1020").ignoresSafeArea()
            Circle().fill(Color(hex: "8B5CF6").opacity(0.22)).blur(radius: 90)
                .frame(width: 380, height: 380).offset(x: -140, y: -320)
            Circle().fill(Color(hex: "3B82F6").opacity(0.14)).blur(radius: 90)
                .frame(width: 340, height: 340).offset(x: 150, y: -140)
            Circle().fill(Color(hex: "D946EF").opacity(0.10)).blur(radius: 100)
                .frame(width: 420, height: 420).offset(x: 0, y: 380)
        }
    }
}

// MARK: - Service icon

struct SvcIcon: View {
    let name: String
    let hex: String

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: 19, weight: .heavy))
            .foregroundColor(.white)
            .frame(width: 46, height: 46)
            .background(Color(hex: hex))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Badge

struct BadgeView: View {
    let text: String
    let color: Color
    let bg: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(bg)
            .foregroundColor(color)
            .cornerRadius(999)
    }
}

// MARK: - Subscription row

/// A row always shows the subscription's own currency — switching the app's
/// country never relabels a price that was entered earlier.
struct SubscriptionRow: View {
    let subscription: Subscription
    var onOptions: () -> Void

    private var country: Country { Country.from(currencyCode: subscription.currencyCode) }

    var body: some View {
        HStack(spacing: 13) {
            SvcIcon(name: subscription.name, hex: subscription.colorHex)

            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("\(renewalText(for: subscription)) · \(shortDate(subscription.nextRenewal))")
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                (Text(money(subscription.price, currencyCode: subscription.currencyCode))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                + Text("/\(subscription.cycle.short)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35)))

                HStack(spacing: 4) {
                    if subscription.isTrial {
                        BadgeView(text: String(localized: "TRIAL"), color: Color(hex: "FBBF24"), bg: Color(hex: "FBBF24").opacity(0.15))
                    }
                    if subscription.autopay {
                        BadgeView(text: country.autopayLabel.uppercased(), color: Color(hex: "34D399"), bg: Color(hex: "34D399").opacity(0.15))
                    } else if !subscription.isTrial && subscription.daysLeft <= 7 {
                        BadgeView(text: String(localized: "SOON"), color: Color(hex: "C4A8FF"), bg: Color(hex: "8B5CF6").opacity(0.18))
                    }
                }
            }

            Button(action: onOptions) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white.opacity(0.35))
                    .padding(6)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.045))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Helpers

func renewalText(for sub: Subscription) -> String {
    let n = sub.daysLeft
    if n <= 0 { return String(localized: "Renews today") }
    if n == 1 { return sub.isTrial ? String(localized: "Trial ends tomorrow") : String(localized: "Renews tomorrow") }
    let fmt = String(localized: sub.isTrial ? "Trial ends in %@" : "Renews in %@")
    return String(format: fmt, "\(n)")
}

func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yy"
    return f.string(from: date)
}

func greeting() -> String {
    let h = Calendar.current.component(.hour, from: Date())
    if h < 12 { return String(localized: "Good morning") }
    if h < 17 { return String(localized: "Good afternoon") }
    return String(localized: "Good evening")
}
