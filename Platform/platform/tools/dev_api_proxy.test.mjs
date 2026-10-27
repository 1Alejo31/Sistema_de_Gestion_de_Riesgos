import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { once } from 'node:events';
import { spawn } from 'node:child_process';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

test('local proxy forwards API requests and confines origins and destinations', async (t) => {
  const calls = [];
  const upstream = http.createServer(async (request, response) => {
    let body = '';
    for await (const chunk of request) body += chunk;
    calls.push({ method: request.method, path: request.url, body, headers: request.headers });
    if (request.url.endsWith('/redirect')) {
      response.writeHead(302, { Location: '/api/v1/unexpected' });
      return response.end();
    }
    response.writeHead(201, {
      'Content-Type': 'application/json',
      'X-Correlation-Id': 'proxy-test-id',
      'Set-Cookie': 'must-not-be-forwarded=1',
    });
    response.end(JSON.stringify({ data: { accepted: true } }));
  });
  upstream.listen(0, '127.0.0.1');
  await once(upstream, 'listening');
  t.after(() => upstream.close());
  const reservation = http.createServer();
  reservation.listen(0, '127.0.0.1');
  await once(reservation, 'listening');
  const proxyPort = reservation.address().port;
  await new Promise((resolve) => reservation.close(resolve));
  const directory = await mkdtemp(join(tmpdir(), 'sgsst-proxy-test-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const settingsPath = join(directory, 'development.json');
  await writeFile(settingsPath, JSON.stringify({
    upstreamOrigin: `http://127.0.0.1:${upstream.address().port}`,
    frontendOrigin: 'http://localhost:8090',
    proxyPort,
  }));
  const proxy = spawn(process.execPath, [
    fileURLToPath(new URL('./dev_api_proxy.mjs', import.meta.url)), settingsPath,
  ], { windowsHide: true });
  t.after(() => proxy.kill());
  await Promise.race([
    once(proxy.stdout, 'data'),
    once(proxy, 'exit').then(() => { throw new Error('Proxy failed to start'); }),
  ]);
  const origin = { Origin: 'http://localhost:8090' };
  const base = `http://127.0.0.1:${proxyPort}`;
  let result = await fetch(`${base}/api/v1/auth/login`, { method: 'OPTIONS', headers: origin });
  assert.equal(result.status, 204);
  assert.equal(result.headers.get('access-control-allow-origin'), origin.Origin);
  assert.equal(calls.length, 0);
  const arbitraryLocalOrigin = 'http://localhost:54321';
  result = await fetch(`${base}/api/v1/auth/login`, {
    method: 'OPTIONS', headers: { Origin: arbitraryLocalOrigin },
  });
  assert.equal(result.status, 204);
  assert.equal(result.headers.get('access-control-allow-origin'), arbitraryLocalOrigin);
  result = await fetch(`${base}/api/v1/auth/login`, {
    method: 'POST',
    headers: { ...origin, 'Content-Type': 'application/json', Authorization: 'Bearer test-marker', Cookie: 'ignore=1' },
    body: JSON.stringify({ email: 'fixture@example.invalid', password: 'test-marker' }),
  });
  assert.equal(result.status, 201);
  assert.equal(result.headers.get('x-correlation-id'), 'proxy-test-id');
  assert.equal(result.headers.get('set-cookie'), null);
  assert.deepEqual(await result.json(), { data: { accepted: true } });
  assert.equal(calls[0].method, 'POST');
  assert.equal(calls[0].path, '/api/v1/auth/login');
  assert.equal(calls[0].headers.authorization, 'Bearer test-marker');
  assert.equal(calls[0].headers.cookie, undefined);
  assert.equal(calls[0].headers.origin, undefined);
  assert.deepEqual(JSON.parse(calls[0].body), { email: 'fixture@example.invalid', password: 'test-marker' });
  for (const [path, headers, status] of [
    ['/api/v1/auth/me', {}, 403],
    ['/api/v1/auth/me', { Origin: 'https://untrusted.example' }, 403],
    ['/api/v1/bootstrap', origin, 404],
    ['/api/v1/auth/login?destination=other', origin, 404],
  ]) {
    result = await fetch(`${base}${path}`, { headers });
    assert.equal(result.status, status);
  }
  assert.equal(calls.length, 1);
  result = await fetch(`${base}/api/v1/redirect`, { headers: origin });
  assert.equal(result.status, 502);
  assert.equal(calls.length, 2);
});
