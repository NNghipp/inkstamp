# Development setup

## 1. Install Flutter

Install the current Flutter stable SDK and add `flutter/bin` to `PATH`.
Confirm:

```powershell
flutter doctor -v
```

This repository was created in an environment without Flutter. Generate the
platform shells once after installation:

```powershell
Set-Location apps/mobile
flutter create --platforms=android,ios --org com.inkstamp .
flutter pub get
```

Keep the existing `lib`, `pubspec.yaml`, `analysis_options.yaml`, and `test`
files if Flutter asks about conflicts.

Use Java 17 or the JDK bundled with Android Studio for Android builds.

## 2. Firebase

Install and authenticate:

```powershell
npm install --global firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

Create `inkstamp-dev`, then:

```powershell
Copy-Item .firebaserc.example .firebaserc
Set-Location apps/mobile
flutterfire configure --project inkstamp-dev `
  --platforms android,ios `
  --android-package-name com.inkstamp.app `
  --ios-bundle-id com.inkstamp.app
```

Enable Apple and Google providers, Firestore, Storage, Cloud Functions,
Cloud Messaging, App Check, Analytics and Crashlytics in the Firebase console.

## 3. Run

The UI works with in-memory repositories:

```powershell
Set-Location apps/mobile
flutter run
```

Backend:

```powershell
Set-Location functions
npm install
npm run build
npm test
npx firebase-tools emulators:start
```

## 4. Native widgets

Reference implementations live in the iOS and Android platform folders. The
iOS target requires an App Group named `group.com.inkstamp.app`. Android needs
the widget receiver declared in the generated application manifest.

Background delivery is best-effort. Always refresh the shared widget cache
when the Flutter application resumes.

## 5. Before beta

- Replace in-memory repositories with Firebase adapters.
- Add real Apple and Google credentials.
- Configure APNs and FCM.
- Enable App Check enforcement after debug tokens are registered.
- Replace placeholder policy/support actions with hosted documents.
- Confirm `inkstamp.app`, store listings and bundle identifiers are available.
- Run the full real-device matrix and security Rules emulator suite.

