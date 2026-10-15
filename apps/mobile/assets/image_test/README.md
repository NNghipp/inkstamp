# DEV sample captures

Put personal demo images directly in this folder, then stop/rebuild the app
(asset discovery is build-time; hot reload alone does not add new files).
No filename list or Dart edits are needed. Keep this file when removing all
photos so the registered folder still exists.

Run debug with `--dart-define=APP_ENV=dev`, open Camera, and tap the
**DEV sample capture** image icon at the top. Pick a filename to show a static
preview, then press the normal shutter to enter the shared processing,
Post-Capture, audience and send flow. Choose **Camera thật** to return to the
native preview. Hardware capture is unchanged.
An empty folder gives a message and leaves the real camera usable.

JPEG, PNG, WebP, GIF, BMP, TIFF and the other filename formats decoded by the
existing Dart `image` library are discoverable. HEIC/HEIF is not supported;
convert it to JPEG first. Animated inputs become a still stamp PNG. Invalid files
are rejected by the normal processor. No photo picker/media permission is added.

The action and raw asset source are blocked outside debug DEV, including
profile/release and production debug builds. Standard Flutter pubspec assets
are still bundled in builds: this folder is **not a secret store**. Remove
personal photos before distributing a public/release build. Source photos are
not modified; only app-private temporary copies/processed drafts are cleaned.

Real upload/publish/Inbox/Calendar/Detail still require the normal configured
DEV backend/auth. This source does not mock them or bypass authorization.

Optional `demo_metadata.json` maps filenames to `title`, `locationLabel` and
`time` (`HH:mm` on the current local day). It is only used in debug DEV.
Unknown photos still work and use the actual capture time without labels.
