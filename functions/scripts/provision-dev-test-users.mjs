// Trusted, local setup only. Never imported by the deployed Functions entrypoint.
import { randomBytes } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFile, writeFile } from 'node:fs/promises';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const projectId = 'inkstamp-dev';
process.on('uncaughtException', (error) => {
  // Do not dump SDK error/request objects; they can contain credentials.
  console.error(`DEV setup failed (${error.code ?? error.status ?? 'unknown'}). Review local permissions/configuration.`);
  process.exitCode = 1;
});
if (process.argv.slice(2).join(' ') !== '--project inkstamp-dev --provision') {
  throw new Error('Only --project inkstamp-dev --provision is accepted.');
}
if (process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('This setup targets real DEV Firebase, not emulator identities.');
}
const workspace = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const localPath = join(workspace, '.env.dev-test-auth.json');
const require = createRequire(import.meta.url);
const npmRoot = execFileSync(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['root', '-g'], {
  encoding: 'utf8', shell: process.platform === 'win32', windowsHide: true,
}).trim();
const cliRoot = join(npmRoot, 'firebase-tools/lib');
const cliAuth = require(join(cliRoot, 'auth.js'));
const account = cliAuth.getProjectDefaultAccount(workspace);
if (!account) throw new Error('Run firebase login with authorized DEV admin first.');
cliAuth.setActiveAccount({}, account);
const { Client } = require(join(cliRoot, 'apiv2.js'));
const config = new Client({ urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'admin/v2' });
await config.patch(`projects/${projectId}/config`, {
  signIn: { email: { enabled: true, passwordRequired: true } },
}, {
  queryParams: { updateMask: 'signIn.email.enabled,signIn.email.passwordRequired' },
});

let local = { projectId, accounts: {} };
try {
  local = JSON.parse(await readFile(localPath, 'utf8'));
  if (local.projectId !== projectId) throw new Error('Local credential project mismatch.');
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}
const app = initializeApp({
  projectId,
  credential: {
    async getAccessToken() {
      const token = await cliAuth.getAccessToken(account.tokens.refresh_token, []);
      return { access_token: token.access_token, expires_in: 3600 };
    },
  },
}, 'dev-test-provisioning');
try {
  const auth = getAuth(app);
  const db = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
  const database = `projects/${projectId}/databases/(default)`;
  async function readDocument(path, transaction) {
    try {
      return (await db.get(`${database}/documents/${path}`, { queryParams: { transaction } })).body;
    } catch (error) {
      if (error.status === 404) return null;
      throw error;
    }
  }
  for (const letter of ['a', 'b']) {
    const email = `test-${letter}@inkstamp.dev`;
    const username = `test_${letter}`;
    const displayName = `InkStamp Test ${letter.toUpperCase()}`;
    let user;
    try {
      user = await auth.getUserByEmail(email);
      if (user.disabled) throw new Error('Existing DEV user is disabled; review manually.');
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      const password = randomBytes(24).toString('base64url');
      user = await auth.createUser({ email, password, displayName });
      local.accounts[letter] = { email, uid: user.uid, password };
      // Persist immediately: reruns never reset existing passwords/users.
      await writeFile(localPath, JSON.stringify(local, null, 2), { mode: 0o600 });
    }
    const transaction = (await db.post(`${database}/documents:beginTransaction`, {})).body.transaction;
    try {
      const namePath = `usernames/${username}`;
      const profilePath = `users/${user.uid}`;
      const [name, profile] = await Promise.all([readDocument(namePath, transaction), readDocument(profilePath, transaction)]);
      if (name && name.fields?.userId?.stringValue !== user.uid) throw new Error('Test username is already owned; no overwrite.');
      if (profile?.fields?.username?.stringValue && profile.fields.username.stringValue !== username) {
        throw new Error('Existing profile differs; no overwrite.');
      }
      const fields = {
        username: { stringValue: username }, usernameNormalized: { stringValue: username },
        displayName: { stringValue: displayName }, onboardingComplete: { booleanValue: true },
        onboardingStep: { stringValue: 'complete' },
      };
      const writes = [{
        update: { name: `${database}/documents/${profilePath}`, fields },
        updateMask: { fieldPaths: Object.keys(fields) },
        updateTransforms: [
          { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ...(!profile?.fields?.createdAt ? [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }] : []),
        ],
      }];
      if (!name) writes.push({
        update: { name: `${database}/documents/${namePath}`, fields: { userId: { stringValue: user.uid } } },
        currentDocument: { exists: false },
        updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
      });
      await db.post(`${database}/documents:commit`, { writes, transaction });
    } catch (error) {
      await db.post(`${database}/documents:rollback`, { transaction }).catch(() => {});
      throw error;
    }
    console.log(JSON.stringify({ projectId, email, uid: user.uid, username,
      profile: 'ready', localPasswordAvailable: local.accounts[letter]?.uid === user.uid }));
  }
  console.log('Credentials stored locally in ignored .env.dev-test-auth.json; do not print/commit/share.');
} finally {
  await deleteApp(app);
}
