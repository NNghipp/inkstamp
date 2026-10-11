# Camera hardware verification — 2026-10-05

Device: `emulator-5554`, AVD `Medium_Phone_API_36.1`.
Reported model/product: `sdk_gphone64_x86_64`.
Reported Android SDK/API level: **36**.
Test accounts: **none**; this test exercises real camera/image processing only.

Command from `apps/mobile`:

```powershell
flutter test --no-pub integration_test/camera_hardware_test.dart -d emulator-5554
```

Observed terminal result:

```text
01:46 +1: (tearDownAll)
01:47 +1: All tests passed!
```

PASS assertions: back camera capture, front lens switching and capture,
1440×1440 processed image, 512×512 thumbnail, empty EXIF, 5 MB image limit,
raw capture deletion, processed-draft cleanup and camera disposal. Real-world
orientation/crop appearance on physical phones is not proved by this emulator
test. Flash mode calls did not fail; physical flash behavior is not proved.

The integration test uses the production `CameraPluginRepository` and
`LocalImageProcessingRepository`. It does not stub camera hardware or the
processor. It does not invoke upload/publish/delivery and does not prove those
parts of E2E. The supporting `emulator-environment.png` shows the emulator's
environment after Flutter terminated the test activity; it is not evidence of
the captured photo or a successful publish.

Installation note: the emulator first reported insufficient internal storage.
Flutter automatically uninstalled the old InkStamp app and retried installation.
Old app data/session may have been removed; an APK reinstall cannot restore it.
Subsequent normal-APK restoration uses explicit `adb install -r` without an
uninstall fallback. Full two-account E2E requires fresh authenticated sessions.
An earlier normal-app x86_64 build was restored successfully. A subsequent
in-place update to the final build failed with insufficient storage, leaving
that earlier normal-app build installed. The final source and debug APK build
successfully; this installation limit is separate from the hardware test PASS.
