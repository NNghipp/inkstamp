// Trusted pagination fixtures only, NOT evidence of 126 real publishes/uploads.
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const argumentsText = process.argv.slice(2).join(' ');
const resetTestQuota = argumentsText === '--project inkstamp-dev --seed --reset-test-a-friend-quota';
if (argumentsText !== '--project inkstamp-dev --seed' && !resetTestQuota) throw new Error('Explicit DEV fixture mode required.');
const workspace = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const accounts = JSON.parse(await readFile(join(workspace, '.env.dev-test-auth.json'), 'utf8'));
if (accounts.projectId !== 'inkstamp-dev') throw new Error('DEV project required');
const require = createRequire(import.meta.url);
const root = execFileSync('npm.cmd', ['root', '-g'], { shell: true, windowsHide: true, encoding: 'utf8' }).trim();
const auth = require(join(root, 'firebase-tools/lib/auth.js'));
const account = auth.getProjectDefaultAccount(workspace);
if (!account) throw new Error('Authorized DEV admin required');
auth.setActiveAccount({}, account);
const { Client } = require(join(root, 'firebase-tools/lib/apiv2.js'));
const db = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
const database = 'projects/inkstamp-dev/databases/(default)';
const a = accounts.accounts.a.uid;
const b = accounts.accounts.b.uid;
if (a !== 'uC6PwltoIQSZ9L54aXDufCxPRLX2' || b !== 'eZUnkmMGsgQI01NJzSjz8m3oavK2') throw new Error('Dedicated A/B fixtures only');
const writes = [];
for (let i = 0; i < 126; i++) {
  const id = `zz_backend_page_20261007_${String(i).padStart(3, '0')}`;
  const name = `${database}/documents/users/${b}/deliveries/${id}`;
  // Refuse to overwrite a colliding non-fixture document.
  try {
    const prior = (await db.get(name)).body;
    if (prior.fields?.devPaginationFixture?.stringValue !== '2026-10-07') throw new Error('Fixture collision');
  } catch (error) { if (error.status !== 404) throw error; }
  writes.push({ update: { name, fields: {
    stampId: { stringValue: id }, senderId: { stringValue: a },
    senderName: { stringValue: 'DEV pagination fixture (not a publish)' },
    status: { stringValue: 'available' }, isSeen: { booleanValue: false },
    frameStyle: { stringValue: 'classic' }, paperTone: { stringValue: 'cream' },
    createdAt: { timestampValue: '2020-01-01T00:00:00.000000Z' },
    cloudinaryPublicId: { stringValue: `inkstamp/${a}/stamp/dev-pagination-${i}` },
    cloudinaryThumbnailPublicId: { stringValue: `inkstamp/${a}/thumbnail/dev-pagination-${i}` },
    devPaginationFixture: { stringValue: '2026-10-07' },
  } } });
}
await db.post(`${database}/documents:commit`, { writes });
console.log('DEV_PAGINATION_FIXTURES=126; PROJECT=inkstamp-dev; RECIPIENT=Test B; REAL_PUBLISHES=0');
if (resetTestQuota) {
  const profile = (await db.get(`${database}/documents/users/${a}`)).body;
  if (profile.fields?.username?.stringValue !== 'test_a') throw new Error('Dedicated Test A profile required');
  const day = new Date().toISOString().slice(0, 10);
  const name = `${database}/documents/users/${a}/dailyQuotas/${day}_friendRequests`;
  const prior = (await db.get(name)).body;
  if (prior.fields?.action?.stringValue !== 'friendRequests') throw new Error('Wrong quota action');
  const evidence = join(workspace, 'artifacts/evidence/2026-10-07/backend-unblock');
  await mkdir(evidence, { recursive: true });
  const recordedAt = new Date().toISOString();
  await writeFile(join(evidence, `test-a-quota-before-${recordedAt.replace(/[:.]/g, '-')}.json`), JSON.stringify({ recordedAt, projectId: 'inkstamp-dev', prior }, null, 2), 'utf8');
  await db.post(`${database}/documents:commit`, { writes: [{
    update: { name, fields: { count: { integerValue: '0' } } },
    updateMask: { fieldPaths: ['count'] }, currentDocument: { updateTime: prior.updateTime },
  }] });
  console.log(`DEV_TEST_A_FRIEND_QUOTA_RESET; PRIOR_COUNT=${prior.fields.count.integerValue}; PRODUCT_LIMIT_UNCHANGED=20; DAY=${day}`);
}
