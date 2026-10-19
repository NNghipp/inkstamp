// Runtime credentials go to the debuggable app's private files directory only.
import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawn, spawnSync } from 'node:child_process';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { startFaultProxy } from './dev-callable-fault-proxy.mjs';

const workspace = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const photoReview = process.argv.includes('--photo-review');
const stampEdges = process.argv.includes('--stamp-edges');
const reusePhotos = process.argv.includes('--reuse-photos');
const darkGallery = process.argv.includes('--dark-gallery');
const readmePresentation = process.argv.includes('--readme-presentation');
const config = JSON.parse(await readFile(join(workspace, '.env.dev-test-auth.json'), 'utf8'));
if (config.projectId !== 'inkstamp-dev') throw new Error('Wrong credential project.');
const faultControlSecret = randomUUID();
const credentials = JSON.stringify({ ...config, faultControlSecret });
const sdk = process.env.ANDROID_HOME || join(process.env.LOCALAPPDATA, 'Android/Sdk');
const adb = join(sdk, 'platform-tools/adb.exe');
function adbCall(args, input) {
  const result = spawnSync(adb, ['-s', 'emulator-5554', ...args], { input, encoding: 'utf8', windowsHide: true });
  if (result.status !== 0) throw new Error('ADB private credential transfer/cleanup failed.');
}
let transferred = false;
const evidence = join(workspace, readmePresentation
  ? 'artifacts/evidence/2026-10-15/dev-presentation'
  : darkGallery
  ? 'artifacts/evidence/2026-10-14/dark-gallery'
  : stampEdges
  ? `artifacts/evidence/2026-10-11/stamp-edges${reusePhotos ? '/current' : ''}`
  : photoReview
  ? `artifacts/evidence/2026-10-11/photo-presentation/${process.argv.includes('--before-photos') ? 'before-loaded' : reusePhotos ? 'after' : 'before'}`
  : process.argv.includes('--release-hardening')
  ? 'artifacts/evidence/2026-10-10/release-hardening'
  : 'artifacts/evidence/2026-10-07/backend-unblock');
await mkdir(evidence, { recursive: true });
const proxy = await startFaultProxy(faultControlSecret, async (name) => {
  const path = `/sdcard/inkstamp-backend-${name}.png`;
  adbCall(['shell', 'screencap', '-p', path]);
  adbCall(['pull', path, join(evidence, `${name}.png`)]);
});
try {
  adbCall(['reverse', 'tcp:5002', 'tcp:5002']);
  const child = spawn(process.platform === 'win32' ? 'flutter.bat' : 'flutter', [
    'test', '--no-pub', '--no-uninstall', photoReview ? 'integration_test/photo_presentation_test.dart' : 'integration_test/backend_e2e_test.dart', '-d', 'emulator-5554',
    '--dart-define=APP_ENV=dev', '--dart-define=ENABLE_DEV_TEST_AUTH=true', '--dart-define=BACKEND_MODE=functions_emulator', '--dart-define=DEV_FUNCTIONS_PORT=5002', '--dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787',
    ...(reusePhotos ? ['--dart-define=PHOTO_REVIEW_REUSE=true'] : []),
    ...(stampEdges ? ['--dart-define=STAMP_EDGES_REVIEW=true'] : []),
    ...(darkGallery ? ['--dart-define=DARK_GALLERY_REVIEW=true'] : []),
    ...(readmePresentation ? ['--dart-define=README_PRESENTATION=true'] : []),
  ], { cwd: join(workspace, 'apps/mobile'), shell: process.platform === 'win32', windowsHide: true });
  let output = '';
  function consume(chunk) {
    output += chunk.toString();
    for (const line of chunk.toString().split(/\r?\n/)) {
      if (/^BACKEND_(CASE|STEP)/.test(line) && !/token|secret|password|Bearer/i.test(line)) console.log(line);
    }
    if (!transferred && output.includes(photoReview ? 'real DEV backend photo presentation' : 'real DEV backend A B workflow')) {
      adbCall(['shell', 'run-as', 'com.inkstamp.app', 'touch', 'files/dev-test-auth.json']);
      adbCall(['shell', 'run-as', 'com.inkstamp.app', 'chmod', '600', 'files/dev-test-auth.json']);
      adbCall(['exec-in', 'run-as', 'com.inkstamp.app', 'tee', 'files/dev-test-auth.json'], credentials);
      adbCall(['shell', 'run-as', 'com.inkstamp.app', 'test', '-s', 'files/dev-test-auth.json']);
      transferred = true;
      console.log('Private runtime credential transfer completed after test APK installation.');
    }
  }
  child.stdout.on('data', consume);
  child.stderr.on('data', consume);
  const status = await new Promise((resolve, reject) => { child.on('exit', resolve); child.on('error', reject); });
  // No raw device/SDK logs are persisted or echoed.
  const safe = output.split(/\r?\n/).map(line => line.replace(/(?:https?|file):\/\/\S+/g, '[URL removed]'))
    .filter(line => /BACKEND_CASE|BACKEND_STEP|All tests passed|Some tests failed|DEV backend|\[E\]|Built build|Test failed|SessionStage|Expected:|Actual:|Error:|Exception|firebase_functions\/|cloud_firestore\/|Bad state|Timed out|Tried to modify|widget tree|called during build|following assertion|following StateError|following TestFailure|Unhandled|disposed|mounted|backend_e2e_test.dart:[0-9]+|Use the secure/.test(line) && !/token|secret|password|Bearer|debug provider/i.test(line));
  const completedAt = new Date().toISOString();
  const report = `${completedAt}\n${safe.join('\n')}\nBACKEND_E2E_EXIT=${status}\n`;
  await writeFile(join(evidence, `e2e-${completedAt.replace(/[:.]/g, '-')}.log`), report, 'utf8');
  await writeFile(join(evidence, 'e2e-safe-output.log'), report, 'utf8');
  console.log(safe.join('\n'));
  console.log(`BACKEND_E2E_EXIT=${status}`);
  process.exitCode = status ?? 1;
  if (status === 0 && readmePresentation) {
    const destination = join(workspace, 'artifacts/readme-assets');
    await mkdir(destination, { recursive: true });
    for (const [source, target] of [
      ['camera-sample', 'camera-screen'], ['preview-stamp', 'preview-stamp'],
      ['history', 'history-screen'], ['calendar-selected-day', 'calendar-screen'],
      ['profile', 'profile-collection'], ['detail-0', 'memory-detail'],
    ]) await copyFile(join(evidence, `${source}.png`), join(destination, `${target}.png`));
  }
} finally {
  proxy.close();
  adbCall(['shell', 'run-as', 'com.inkstamp.app', 'rm', '-f', 'files/dev-test-auth.json']);
  adbCall(['reverse', '--remove', 'tcp:5002']);
}
