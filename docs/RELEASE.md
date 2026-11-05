# Release guide (human-only steps)

These steps require accounts, keys, or hardware that only the owner can provide.
Follow them in order. Code-side prep (analyze/test/build) is already green.

## 1. Install tooling
- Flutter SDK (stable), Android Studio (Android SDK + emulator), Xcode on macOS for iOS.
- Verify: `flutter doctor -v` shows no blocking issues.

## 2. Store accounts
- Google Play Console (one-time fee) and Apple Developer Program (annual fee).
- Check current prices on the official sites; they change.

## 3. Bundle id and signing
- Pick a real application id, e.g. `com.<yourname>.calmcorner`.
- Update `android/app/build.gradle` applicationId and `ios/Runner.xcodeproj` bundle id.
- Android: create a keystore:
  `keytool -genkey -v -keystore ~/calmcorner-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias calmcorner`
  Then reference it in `android/key.properties` (git-ignored) and `build.gradle`.
- iOS: configure signing in Xcode with your team; create an App Store provisioning profile.

## 4. Optional services (only if you want them)
- Create Firebase, AdMob, RevenueCat projects. Paste keys into a git-ignored `env.json`:
  `{ "FIREBASE_API_KEY": "...", "ADMOB_APP_ID": "...", "REVENUECAT_KEY": "..." }`
- Build with `flutter build appbundle --release --dart-define-from-file=env.json`.
- MVP default (no keys) = no ads, no analytics, no purchases; Calm Plus screen uses FakePurchases.

## 5. Host the privacy policy
- Publish `docs/PRIVACY_POLICY.md` (draft in repo) to GitHub Pages.
- Paste the public URL into Play Console and App Store Connect.

## 6. Build and upload
- Android: `flutter build appbundle --release` then upload the `.aab` to Play Console.
- iOS: `flutter build ipa --release` then upload via Transporter / Xcode.

## 7. Final QA on real devices (section 16.5)
- Low-end Android (3 GB RAM), mid Android 120 Hz, iPhone SE, recent iPhone, tablet.
- Check audio interruptions, silent switch, haptics on both OSes, Reduce Motion, text scale 1.6x, TalkBack/VoiceOver, rotating tablets, 30-minute soak (no memory growth).

## 8. Performance
- Run `integration_test/perf_test.dart` in profile mode on a real device; verify budgets in section 4.7.
