import { spawn, spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { mkdir, writeFile } from 'node:fs/promises';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const adb = join(process.env.LOCALAPPDATA, 'Android/Sdk/platform-tools/adb.exe');
const evidence = join(root, 'artifacts/evidence/2026-10-15/dev-presentation');
await mkdir(evidence, { recursive: true });
const child = spawn('flutter.bat', ['test', '--no-uninstall',
  'integration_test/camera_lifecycle_stress_test.dart', '-d', 'emulator-5554',
  '--dart-define=APP_ENV=dev'], { cwd: join(root, 'apps/mobile'), shell: true, windowsHide: true });
let output = '';
const seen = new Set();
const safe = [];
function adbCall(args) {
  const result = spawnSync(adb, ['-s', 'emulator-5554', ...args], { windowsHide: true });
  if (result.status !== 0) throw new Error('Camera stress ADB operation failed.');
}
function consume(chunk) {
  output += chunk;
  for (const line of output.split(/[\r\n]+/)) {
    const match = line.match(/HARDENING ([A-Za-z0-9_= .]+)/);
    if (!match || seen.has(match[1])) continue;
    const step = match[1];
    seen.add(step); safe.push(step); console.log(step);
    if (step.endsWith('BACKGROUND_REQUEST')) {
      adbCall(['shell', 'input', 'keyevent', 'KEYCODE_HOME']);
      setTimeout(() => {
        adbCall(['shell', 'am', 'start', '-n', 'com.inkstamp.app/.MainActivity']);
      }, 1500);
    }
  }
}
child.stdout.on('data', consume); child.stderr.on('data', consume);
const status = await new Promise((done, reject) => {
  child.on('exit', done); child.on('error', reject);
});
if (status !== 0) {
  // Camera-only run, no Firebase initialized. Keep only assertion diagnostics.
  safe.push(...output.split(/[\r\n]+/).filter(line =>
    /Expected:|Actual:|Camera failed|Some tests failed|camera_lifecycle_stress_test.dart:\d+|Error:|e: file:|What went wrong|Execution failed|Build failed|build.gradle.kts:\d+/.test(line)));
}
safe.push(`CAMERA_HARDENING_EXIT=${status}`);
await writeFile(join(evidence, 'camera-stress.log'), `${safe.join('\n')}\n`);
console.log(`CAMERA_HARDENING_EXIT=${status}`);
process.exitCode = status ?? 1;
