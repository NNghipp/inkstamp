# Dependency security maintenance

## 2026-10-11 patch

This change only updates dependency resolution and CI. It does not enable
billing, upgrade Firebase Spark, deploy Functions/Workers, or modify cloud data.

- Functions: `proxy-addr` 2.0.8, `brace-expansion` 2.1.7 / 5.0.12,
  `source-map-js` 1.2.2 and `@grpc/grpc-js` 1.14.6.
- Gateway tooling: Wrangler 4.149.0 resolves patched Sharp 0.35.5,
  Undici 7.29.1 and `source-map-js` 1.2.2.
- Firebase's test-side Firestore SDK still requests gRPC `~1.9.0`, including
  the latest SDK inspected at patch time. A scoped npm override selects
  gRPC 1.14.6 for `@firebase/firestore`; backend gRPC resolves the same patched
  version through its existing range. Remove the override only once the
  upstream SDK requests a patched version and emulator tests pass.
- Existing UUID and Linux Rolldown overrides are retained. No forced audit
  fix, Firebase major-version migration, or application logic change is used.

Both npm projects now run `npm audit --audit-level=low` in CI after `npm ci`.
Audit findings and GitHub alerts are snapshots, not a guarantee against future
vulnerabilities; recheck them when updating dependencies.

## Golden test reproducibility

The original Linux CI run passed 125 Flutter tests but failed all five pixel
goldens generated and reviewed on Windows. The Flutter job now uses
`windows-latest` and Flutter 3.47.1, matching the baseline generation SDK/OS.
All 130 tests still run with coverage; golden files and exact pixel comparison
are unchanged. A Flutter/runner rendering upgrade requires an explicit visual
review, not automatic baseline regeneration or a larger comparison tolerance.

## Local verification after clean npm installs

| Check | Result |
| --- | --- |
| Functions npm audit | 0 vulnerabilities |
| Gateway npm audit | 0 vulnerabilities |
| Functions lint / TypeScript build | PASS |
| Functions unit tests | 29 PASS; 15 emulator-dependent tests skipped here |
| Firestore Rules, isolated local emulator | 7/7 PASS |
| Delivery pagination, isolated local emulator | 8/8 PASS |
| Gateway tests | 39/39 PASS |
| Gateway type generation / build / deploy dry-run | PASS; no deployment |
| Flutter analyze | 0 issues |
| Flutter tests including five original goldens | 130/130 PASS |
| Dart formatting | 132 files; 0 changes |
| Local DEV gateway restored | `/health` HTTP 200 |

The emulator tests use isolated `inkstamp-rules-test` and
`inkstamp-pagination-test` data. They do not seed or delete DEV cloud records.

Advisory references:

- [gRPC certificate authentication](https://github.com/grpc/grpc-node/security/advisories/GHSA-m9gg-hp2v-232j)
- [proxy-addr IP spoofing](https://github.com/advisories/GHSA-jqcg-44mw-7w3h)
- [source-map-js denial of service](https://github.com/advisories/GHSA-68fv-2mgg-jv7q)
