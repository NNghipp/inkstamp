# InkStamp — Media Index

Curated on 2026-10-11 and refreshed after photo-layout verification. Curated PNGs are byte-for-byte copies of project renders/captures, not generated mockups or edited composites. Feed/Profile/Calendar copies now reflect the deliberately updated square-photo golden baselines; Camera/Preview remain unchanged. Golden renders use fixture photos/identities: UI reference evidence, not proof of real users, usage statistics or native capture.

## Available Visuals

| Filename | Screen/feature | Source | Current? | Recommended use |
|---|---|---|---|---|
| [camera-golden.png](screenshots/camera-golden.png) | Camera layout | [camera.png](../../apps/mobile/test/goldens/camera.png) | Frozen baseline unchanged; fixture preview | README/GitHub/CV UI example, label golden |
| [post-capture-golden.png](screenshots/post-capture-golden.png) | Preview/audience | [preview.png](../../apps/mobile/test/goldens/preview.png) | Frozen baseline unchanged; sample people | README/GitHub/interview; not an actual send screenshot |
| [history-golden.png](screenshots/history-golden.png) | Moments/History | [feed.png](../../apps/mobile/test/goldens/feed.png) | Updated square-photo baseline; sample memories | README/GitHub UI example |
| [calendar-golden.png](screenshots/calendar-golden.png) | Calendar design | [calendar.png](../../apps/mobile/test/goldens/calendar.png) | Updated square-photo baseline; fixture dates | README/CV UI example |
| [profile-golden.png](screenshots/profile-golden.png) | Profile/collection | [profile.png](../../apps/mobile/test/goldens/profile.png) | Updated square-photo baseline; sample name/counts | README/GitHub; counts are not usage metrics |
| [inbox-dev-e2e.png](screenshots/inbox-dev-e2e.png) | Real DEV Inbox | [received-inbox.png](../evidence/2026-10-10/release-hardening/received-inbox.png) | 2026-10-11 replay; visible test fixtures | Interview evidence; not hero/CV screenshot |
| [calendar-dev-e2e.png](screenshots/calendar-dev-e2e.png) | Real selected-day memory | [calendar-selected-day.png](../evidence/2026-10-10/release-hardening/calendar-selected-day.png) | 2026-10-11 replay; emulator camera scene | Interview evidence; distinguishes live data from goldens |
| [revoked-detail-dev-e2e.png](screenshots/revoked-detail-dev-e2e.png) | Unavailable Detail after revoke | [revoked-detail.png](../evidence/2026-10-10/release-hardening/revoked-detail.png) | 2026-10-11 replay | Interview/error-state evidence, not loaded memory hero |
| [sign-in-dev.png](screenshots/sign-in-dev.png) | Ordinary APK / A/B controls | [ordinary-dev-sign-in.png](../evidence/2026-10-10/release-hardening/ordinary-dev-sign-in.png) | Final 2026-10-11 DEV APK | Demo setup/interview; Google/Apple buttons are not E2E proof |
| [architecture.mmd](diagrams/architecture.mmd) | High-level DEV architecture | Authored from current repository paths | Current schematic, not a deployment inventory | README/GitHub/interview; rendered in overview |
| [user-flow.mmd](diagrams/user-flow.mmd) | Logical capture→memory flow | Current Post-Capture/Inbox/Calendar flow | Current; preview/audience share one screen | README/GitHub/interview; rendered in overview |

Evidence folder name retains the phase start date 2026-10-10; the successful replay/captures occurred 2026-10-11. Original evidence is preserved, not moved or cleaned away.

Latest real personal-photo evidence: [ordinary DEV History](../evidence/2026-10-11/photo-presentation/after/ordinary-dev-history-loaded.png), [Profile](../evidence/2026-10-11/photo-presentation/after/profile.png), [loaded Detail](../evidence/2026-10-11/photo-presentation/after/detail-0.png), [scrolled Calendar photo](../evidence/2026-10-11/photo-presentation/after/ordinary-calendar-day.png), [B Inbox](../evidence/2026-10-11/photo-presentation/after/inbox-b.png). These are unedited captures of actual published DEV memories, not golden fixtures. See [before/after, source filenames, tests and boundaries](../PHOTO_PRESENTATION.md). Personal-photo redistribution rights still require review.

## Reviewed but Not Promoted

[Received Detail capture](../evidence/2026-10-10/release-hardening/received-detail.png) is still loading; do not use it to claim a fully decoded image. [Camera return capture](../evidence/2026-10-10/release-hardening/custom-camera-return.png) includes a System UI ANR dialog. Both remain in technical evidence, not the curated hero set. The ANR/intervention is disclosed in the [verification report](../evidence/2026-10-10/release-hardening/result.md).

## Assets Still Missing

- 60–90 second real DEV screen recording of A capture/send → B Inbox/loaded Detail/Calendar; no passwords, console tokens or private URL overlays.
- Clean native Camera and Post-Capture captures from the ordinary DEV APK (not the golden sample preview).
- A polished recording set across ordinary Camera/Post-Capture and both accounts; the latest loaded photo views above are available. Capture existing UI only; do not delete backend data just to improve screenshots.
- Optional short lifecycle/retry GIF from a genuine recording. No GIF/video is fabricated or currently linked as if available.

Use only owner-controlled test media and confirm supplied design/photo licenses before broader redistribution. Copies do not establish third-party image rights. Never include credentials or someone else's private memories.

[Capture guidance](gifs/README.md) · [Diagram sources](diagrams/README.md) · [Recruiter demo](../RECRUITER_DEMO.md) · [Packaging checks](VERIFICATION.md)
