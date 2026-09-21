import SwiftUI
import SwiftData
import StoreKit
import UIKit
import UserNotifications

/// Settings: iCloud sync status, language, notifications, data export, about.
/// Everything here is App Store policy safe: no private APIs, no tracking,
/// iCloud is optional with a local fallback, and nothing leaves the device
/// except the user's own private CloudKit database.
struct SettingsView: View {
    @Query private var subscriptions: [Subscription]
    @AppStorage("countryCode") private var countryCode = Country.india.rawValue
    @AppStorage("iCloudSyncEnabled") private var iCloudSync = true
    @AppStorage("appLanguage") private var appLanguage = "en"

    @State private var iCloudStatus: String = String(localized: "Checking…")
    @State private var notifStatus: String = String(localized: "Checking…")
    @State private var notifDenied = false
    @State private var notifUndetermined = true
    @State private var showRestartAlert = false
    @State private var shareURL: URL?
    @State private var showShare = false

    private struct AppLanguage: Identifiable {
        let id: String
        let name: String
    }
    private let languages = [
        AppLanguage(id: "en", name: "English"),
        AppLanguage(id: "hi", name: "हिन्दी")
    ]

    private var country: Country { Country(rawValue: countryCode) ?? .india }

    private var versionText: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Settings")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 56)

                        iCloudSection
                        languageSection
                        notificationsSection
                        dataSection
                        aboutSection
                    }
                    .padding(.bottom, 110)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            refreshICloudStatus()
            refreshNotifStatus()
        }
        .alert("Restart required", isPresented: $showRestartAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please close and reopen Renewly to apply this change.")
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - iCloud & Sync

    private var iCloudSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("iCloud & Sync")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 0) {
                HStack {
                    Label("iCloud account", systemImage: "icloud")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(iCloudStatus)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(16)

                Divider().background(Color.white.opacity(0.08)).padding(.leading, 16)

                Toggle(isOn: $iCloudSync) {
                    Label("Sync across devices", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .tint(Color(hex: "8B5CF6"))
                .padding(16)
                .onChange(of: iCloudSync) { _ in showRestartAlert = true }
            }
            .background(Color.white.opacity(0.045))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text("Your subscriptions sync through your private CloudKit database — only you can read it. Turn this off to keep everything only on this iPhone.")
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.45))
                .padding(.horizontal, 22)
                .padding(.top, 8)
        }
    }

    private func refreshICloudStatus() {
        // Never use CKContainer.default() here: without the iCloud capability
        // enabled in Xcode it traps at runtime (EXC_BREAKPOINT). The ubiquity
        // identity token is the safe, Apple-recommended iCloud sign-in check.
        iCloudStatus = FileManager.default.ubiquityIdentityToken == nil
            ? String(localized: "Not signed in")
            : String(localized: "Signed in")
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Language")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 0) {
                ForEach(languages) { lang in
                    Button {
                        appLanguage = lang.id
                        UserDefaults.standard.set([lang.id], forKey: "AppleLanguages")
                        showRestartAlert = true
                    } label: {
                        HStack {
                            Text(lang.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            if appLanguage == lang.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "A78BFA"))
                            }
                        }
                        .padding(16)
                    }
                    if lang.id != languages.last?.id {
                        Divider().background(Color.white.opacity(0.08)).padding(.leading, 16)
                    }
                }
            }
            .background(Color.white.opacity(0.045))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text("Restart the app to apply your language.")
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.45))
                .padding(.horizontal, 22)
                .padding(.top, 8)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Notifications")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 12) {
                HStack {
                    Label("Renewal reminders", systemImage: "bell.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(notifStatus)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Button { handleNotifAction() } label: {
                    Text(notifDenied ? "Open Settings" : "Enable notifications")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "8B5CF6"))
                        .cornerRadius(14)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.045))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text("Renewly reminds you a day before every renewal and trial end — at 9:00 AM, never more.")
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.45))
                .padding(.horizontal, 22)
                .padding(.top, 8)
        }
    }

    private func refreshNotifStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let label: String
            switch s.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                label = String(localized: "On")
            case .denied:
                label = String(localized: "Off")
            default:
                label = String(localized: "Not asked yet")
            }
            DispatchQueue.main.async {
                notifStatus = label
                notifDenied = s.authorizationStatus == .denied
                notifUndetermined = s.authorizationStatus == .notDetermined
            }
        }
    }

    private func handleNotifAction() {
        if notifDenied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } else {
            NotificationManager.shared.requestAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { refreshNotifStatus() }
        }
    }

    // MARK: - Your data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your data")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 12) {
                HStack {
                    Label("Subscriptions", systemImage: "externaldrive")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(subscriptions.count) tracked")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                HStack(spacing: 10) {
                    Button { exportCSV() } label: {
                        Text("Export CSV")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                    }
                    Button { exportJSON() } label: {
                        Text("Export JSON")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.045))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    private func exportCSV() {
        var rows = ["Name,Price,Currency,Cycle,Category,Renews On,Status"]
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        for s in subscriptions {
            let name = s.name.replacingOccurrences(of: "\"", with: "\"\"")
            rows.append("\"\(name)\",\(s.price),\(s.currencyCode),\(s.cycle.rawValue),\(s.category.rawValue),\(f.string(from: s.nextRenewal)),\(s.isCancelled ? "cancelled" : "active")")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("renewly-subscriptions.csv")
        try? rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        shareURL = url
        showShare = true
    }

    private func exportJSON() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let items: [[String: Any]] = subscriptions.map { s in
            ["name": s.name, "price": s.price, "currency": s.currencyCode,
             "cycle": s.cycle.rawValue, "category": s.category.rawValue,
             "renewsOn": f.string(from: s.nextRenewal),
             "status": s.isCancelled ? "cancelled" : "active"]
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("renewly-subscriptions.json")
        if let data = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: url)
        }
        shareURL = url
        showShare = true
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 12) {
                HStack {
                    Label("Renewly", systemImage: "heart.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(versionText)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Text("Renewly has no servers, no ads and no tracking. Your data lives on your devices and in your private iCloud — we can't see any of it.")
                    .font(.system(size: 13.5))
                    .foregroundColor(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button { rateApp() } label: {
                    Text("Rate Renewly")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "D946EF")], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                }

                Text("© 2026 Renewly")
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .background(Color.white.opacity(0.045))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
