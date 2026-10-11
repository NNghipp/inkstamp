// Runtime credentials go to the debuggable app's private files directory only.
import { readFile } from 'node:fs/promises';
import { spawn, spawnSync } from 'node:child_process';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const workspace = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const credentials = await readFile(join(workspace, '.env.dev-test-auth.json'), 'utf8');
if (JSON.parse(credentials).projectId !== 'inkstamp-dev') throw new Error('Wrong credential project.');
const sdk = process.env.ANDROID_HOME || join(process.env.LOCALAPPDATA, 'Android/Sdk');
const adb = join(sdk, 'platform-tools/adb.exe');
function adbCall(args, input) {
  const result = spawnSync(adb, ['-s', 'emulator-5554', ...args], { input, encoding: 'utf8', windowsHide: true });
  if (result.status !== 0) throw new Error('ADB private credential transfer/cleanup failed.');
}
let transferred = false;
try {
  const child = spawn(process.platform === 'win32' ? 'flutter.bat' : 'flutter', [
    'test', '--no-pub', '--no-uninstall', 'integration_test/dev_auth_smoke_test.dart', '-d', 'emulator-5554',
    '--dart-define=APP_ENV=dev', '--dart-define=ENABLE_DEV_TEST_AUTH=true',
  ], { cwd: join(workspace, 'apps/mobile'), shell: process.platform === 'win32', windowsHide: true });
  let output = '';
  function consume(chunk) {
    output += chunk.toString();
    if (!transferred && output.includes('real DEV Firebase A logout B profile/session smoke')) {
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
  const safe = output.split(/\r?\n/).filter(line => /All tests passed|Some tests failed|DEV Firebase|\[E\]|Built build|Test failed|SessionStage|Expected:|Actual:|Error:|dev_auth_smoke_test.dart:|Use the secure/.test(line));
  console.log(safe.join('\n'));
  console.log(`DEV_AUTH_SMOKE_EXIT=${status}`);
  process.exitCode = status ?? 1;
} finally {
  adbCall(['shell', 'run-as', 'com.inkstamp.app', 'rm', '-f', 'files/dev-test-auth.json']);
}
