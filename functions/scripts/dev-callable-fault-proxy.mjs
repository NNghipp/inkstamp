// Test harness only, never imported by Functions/Worker/mobile production code.
import { createServer } from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';

export async function startFaultProxy(controlSecret, screenshot) {
  let armed = false;
  let faultsConsumed = 0;
  let committedStampId = null;
  const expected = createHash('sha256').update(controlSecret).digest();
  const server = createServer(async (request, response) => {
    try {
      const chunks = [];
      let size = 0;
      for await (const chunk of request) {
        size += chunk.length;
        if (size > 65536) { response.writeHead(413).end(); return; }
        chunks.push(chunk);
      }
      if (request.url === '/__dev/fault' || request.url === '/__dev/screenshot') {
        const supplied = createHash('sha256').update(request.headers['x-dev-control'] ?? '').digest();
        if (!timingSafeEqual(expected, supplied)) { response.writeHead(403).end(); return; }
        if (request.url === '/__dev/screenshot') {
          const name = JSON.parse(Buffer.concat(chunks).toString()).name;
          if (!/^[a-z0-9-]{1,40}$/.test(name) || request.method !== 'POST') { response.writeHead(400).end(); return; }
          await screenshot(name);
          response.writeHead(200).end();
          return;
        }
        if (request.method === 'POST') armed = true;
        response.writeHead(200, { 'Content-Type': 'application/json' });
        response.end(JSON.stringify({ armed, faultsConsumed, committedStampId }));
        return;
      }
      if (request.method !== 'POST' || !/^\/inkstamp-dev\/asia-southeast1\/[A-Za-z]+$/.test(request.url ?? '')) {
        response.writeHead(404).end(); return;
      }
      const upstream = await fetch(`http://127.0.0.1:5001${request.url}`, {
        method: 'POST', headers: {
          'Content-Type': 'application/json',
          ...(request.headers.authorization ? { Authorization: request.headers.authorization } : {}),
          ...(request.headers['x-firebase-appcheck'] ? { 'X-Firebase-AppCheck': request.headers['x-firebase-appcheck'] } : {}),
        }, body: Buffer.concat(chunks), signal: AbortSignal.timeout(120000),
      });
      const bytes = await upstream.arrayBuffer();
      if (armed && request.url.endsWith('/publishStamp') && upstream.ok) {
        committedStampId = JSON.parse(Buffer.from(bytes).toString()).result?.stampId ?? null;
        armed = false;
        faultsConsumed++;
        response.writeHead(503, { 'Content-Type': 'application/json' });
        response.end(JSON.stringify({ error: { status: 'UNAVAILABLE', message: 'Injected DEV response loss after commit.' } }));
        return;
      }
      response.writeHead(upstream.status, { 'Content-Type': 'application/json' });
      response.end(Buffer.from(bytes));
    } catch {
      response.writeHead(502, { 'Content-Type': 'application/json' });
      response.end(JSON.stringify({ error: { status: 'UNAVAILABLE', message: 'DEV proxy unavailable.' } }));
    }
  });
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(5002, '127.0.0.1', resolve); });
  return server;
}
