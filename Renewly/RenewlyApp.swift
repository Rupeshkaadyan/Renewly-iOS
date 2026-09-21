import SwiftUI
import SwiftData

@main
struct RenewlyApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    init() {
        // In-app language override (Settings → Language). Apple reads
        // AppleLanguages at launch, so the choice applies on next launch.
        if let code = UserDefaults.standard.string(forKey: "appLanguage"), !code.isEmpty {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(Self.makeContainer())
    }

    /// iCloud (CloudKit) sync when it's available and the user left it on;
    /// otherwise a plain local store. Never crashes, never blocks launch —
    /// if iCloud isn't set up the app just works locally.
    ///
    /// NOTE: enabling iCloud in Xcode (Signing & Capabilities → + Capability
    /// → iCloud → CloudKit) creates the iCloud.com.renewly.app container
    /// automatically. Until then this safely falls back to local storage.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Subscription.self])
        let syncOn = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true
        if syncOn,
           let cloud = try? ModelContainer(for: schema, configurations: [
               ModelConfiguration(isStoredInMemoryOnly: false,
                                  cloudKitDatabase: .private("iCloud.com.renewly.app"))
           ]) {
            return cloud
        }
        if let local = try? ModelContainer(for: schema, configurations: [
            ModelConfiguration(isStoredInMemoryOnly: false)
        ]) {
            return local
        }
        // Practically unreachable — an in-memory store always initialises.
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [
            ModelConfiguration(isStoredInMemoryOnly: true)
        ])
    }
}
