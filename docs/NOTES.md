# Renewly — Developer Notes

Detailed setup, policy, and release notes. The pretty overview lives in [README.md](../README.md).

## iCloud sync (optional)

Out of the box the app works fully offline: if iCloud isn't available the SwiftData
store falls back to local storage — nothing crashes, nothing blocks launch.

To turn on real cross-device sync:

1. Open the project in Xcode → **Renewly** target → **Signing & Capabilities** →
   **+ Capability** → **iCloud**.
2. Tick **CloudKit** and make sure the container `iCloud.com.renewly.app` is checked
   (Xcode creates it).
3. Run the app → **Settings** tab → leave **Sync across devices** on. Restart once
after toggling.

Data syncs through the user's *private* CloudKit database — only the user can read it.

## Localization

- All user-facing strings live in `Renewly/Localizable.xcstrings` (String Catalog)
  with **English** and **Hindi**.
- Settings → Language switches between them (takes effect on restart).
- `hi` is registered in the project's `knownRegions`.
- New strings: add them in code, then open the `.xcstrings` file in Xcode and
  translate — or edit the JSON directly (keep `en` + `hi` for every key).

## Privacy manifest

- `Renewly/PrivacyInfo.xcprivacy`: tracking disabled, no data collected.
- Only "required reason" API: UserDefaults (`CA92.1`, app preferences).
- No third-party SDKs, no analytics, no ads.
- App Store Connect answers: **no data collected**, **no tracking**.

## App Store policy notes

- No private APIs (UIKit, SwiftUI, SwiftData, CloudKit, StoreKit, UserNotifications only).
- Notifications are local and user-initiated; standard system permission prompt.
- In-app language switcher only writes the public `AppleLanguages` default + asks for restart.
- CloudKit sync is opt-out-able in-app and degrades gracefully without the capability.
- Annual-plan savings are nudges to check the provider's pricing page — never invented prices.
- Nothing here guarantees approval; these are the standard reviewer checkboxes, kept clean.

## Before you ship — validation checklist

- [ ] Xcode run on simulator: onboarding → add/edit/delete → Alerts, Stats, Settings render.
- [ ] Edit a price → price-change alert + notification appear.
- [ ] Settings → Language → हिन्दी → restart → UI is in Hindi.
- [ ] Export CSV / JSON and open the shared file.
- [ ] iCloud sync off → restart → data still works locally.
- [ ] With iCloud capability enabled → sync works across devices.
- [ ] App icon installed (see README) — no placeholder ships.
