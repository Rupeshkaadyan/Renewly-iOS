import SwiftUI
import SwiftData

/// Step-by-step cancellation walkthrough. Confirming marks the
/// subscription cancelled so its savings start counting in Stats.
/// Country-specific steps (e.g. UPI mandate revocation) follow the
/// subscription's own currency.
struct CancelGuideView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription

    private var country: Country { Country.from(currencyCode: subscription.currencyCode) }

    private var steps: [(String, LocalizedStringKey)] {
        var list: [(String, LocalizedStringKey)] = [
            ("1", "Open the \(subscription.name) app or website and sign in."),
            ("2", "Go to Account → Subscriptions (or Membership / Billing)."),
            ("3", "Choose Cancel and confirm on every screen until it says you're cancelled."),
        ]
        if country == .india {
            list.append(("4", "Paid via UPI Autopay? Also revoke it: open your UPI app → Autopay / Mandates → cancel the \(subscription.name) mandate, or the charge can still go through."))
        } else {
            list.append(("4", "If you used card autopay, check your bank or card app that no future charge is scheduled."))
        }
        list.append(("5", "Screenshot the cancellation confirmation for your records."))
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How to cancel")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        + Text(" \(subscription.name)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Color(hex: "A78BFA"))

                        Text("Cancelling saves you \(money(subscription.monthlyCost, currencyCode: subscription.currencyCode)) every month.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.62))

                        ForEach(steps, id: \.0) { step in
                            HStack(alignment: .top, spacing: 13) {
                                Text(step.0)
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(Circle())
                                Text(step.1)
                                    .font(.system(size: 14.5))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 5)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.045))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }

                        Button {
                            subscription.isCancelled = true
                            subscription.cancelledAt = Date()
                            NotificationManager.shared.cancel(for: subscription.id)
                            try? context.save()
                            dismiss()
                        } label: {
                            Text("I've cancelled it ✓")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient(colors: [Color(hex: "22C55E"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(999)
                                .shadow(color: Color(hex: "22C55E").opacity(0.35), radius: 14, x: 0, y: 8)
                        }
                        .padding(.top, 6)

                        Button("Not now", role: .cancel) { dismiss() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
