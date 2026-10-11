// Read-only authenticated callable probe. Never prints credentials or SDK logs.
import { readFile } from 'node:fs/promises';
const config = JSON.parse(await readFile(new URL('../../.env.dev-test-auth.json', import.meta.url), 'utf8'));
if (config.projectId !== 'inkstamp-dev') throw new Error('DEV project required');
const options = await readFile(new URL('../../apps/mobile/lib/firebase_options.dart', import.meta.url), 'utf8');
const apiKey = options.match(/apiKey: '([^']+)'/)[1];
const login = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: config.accounts.a.email, password: config.accounts.a.password, returnSecureToken: true }),
});
const session = await login.json();
console.log(`DEV_LOGIN_HTTP=${login.status}; UID_MATCH=${session.localId === config.accounts.a.uid}`);
if (!login.ok) {
  const code = String(session.error?.message ?? '').split(' : ')[0];
  console.log(`DEV_LOGIN_ERROR=${/^[A-Z_]+$/.test(code) ? code : 'unavailable'}`);
  process.exit(1);
}
const base = 'http://127.0.0.1:5001/inkstamp-dev/asia-southeast1/';
const parts = session.idToken.split('.');
parts[2] = (parts[2][0] === 'A' ? 'B' : 'A') + parts[2].slice(1);
for (const [label, token] of [['missing', null], ['forged', parts.join('.')], ['real', session.idToken]]) {
  const response = await fetch(`${base}findUserByUsername`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data: { username: 'test_b' } }),
  });
  const result = await response.json();
  console.log(`CALLABLE_${label.toUpperCase()}_HTTP=${response.status}; ERROR=${result.error?.status ?? 'none'}; TARGET_MATCH=${result.result?.user?.id === config.accounts.b.uid}`);
}
