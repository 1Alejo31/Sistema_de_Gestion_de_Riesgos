import http from 'node:http';
import https from 'node:https';
import { readFileSync } from 'node:fs';

// Development only: the browser talks to loopback; this process forwards API
// requests to the configured server. Never log request headers or bodies.
const configPath = process.argv[2] || new URL('../config/development.json', import.meta.url);
const config = JSON.parse(readFileSync(configPath, 'utf8'));
const upstream = new URL(config.upstreamOrigin);
const frontend = new URL(config.frontendOrigin);
if (!['http:', 'https:'].includes(upstream.protocol) ||
    upstream.origin !== config.upstreamOrigin || upstream.username || upstream.password ||
    frontend.origin !== config.frontendOrigin || frontend.protocol !== 'http:' ||
    !['localhost', '127.0.0.1'].includes(frontend.hostname) ||
    !Number.isInteger(config.proxyPort) || config.proxyPort < 1024 || config.proxyPort > 65535) {
  throw new Error('Invalid development proxy configuration');
}

const server = http.createServer((request, response) => {
  let origin;
  try { origin = new URL(request.headers.origin); } catch { /* rejected below */ }
  // Flutter run chooses random ports in Chrome. Accept HTTP loopback origins
  // so its default launch uses the proxy without requiring special flags.
  const allowedOrigin = origin && origin.protocol === 'http:' &&
    ['localhost', '127.0.0.1', '[::1]'].includes(origin.hostname) &&
    origin.origin === request.headers.origin;
  const cors = {
    ...(allowedOrigin ? { 'Access-Control-Allow-Origin': origin.origin } : {}),
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, Accept, X-Organization-Id',
    'Access-Control-Expose-Headers': 'X-Correlation-Id',
    'Vary': 'Origin',
    'Cache-Control': 'no-store',
  };
  const fail = (status, code) => {
    response.writeHead(status, { ...cors, 'Content-Type': 'application/json' });
    response.end(JSON.stringify({ error: { code } }));
  };
  // Require a browser origin, even for preflights, to restrict this loopback API.
  if (!allowedOrigin) return fail(403, 'FORBIDDEN');
  if (!/^\/api\/v1\/[A-Za-z0-9_/-]+$/.test(request.url || '') ||
      /^\/api\/v1\/bootstrap(?:\/|$)/.test(request.url)) return fail(404, 'NOT_FOUND');
  if (request.method === 'OPTIONS') {
    response.writeHead(204, cors);
    return response.end();
  }
  if (!['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method)) {
    return fail(405, 'METHOD_NOT_ALLOWED');
  }
  // Only explicit API headers cross the proxy boundary. No cookies or origins.
  const headers = {};
  for (const name of ['accept', 'content-type', 'authorization', 'x-organization-id']) {
    if (request.headers[name]) headers[name] = request.headers[name];
  }
  const transport = upstream.protocol === 'https:' ? https : http;
  const forwarded = transport.request(new URL(request.url, upstream), {
    method: request.method,
    headers,
  }, (remote) => {
    // Redirects must never forward a user's credentials to another destination.
    if (remote.statusCode >= 300 && remote.statusCode < 400) {
      remote.resume();
      return fail(502, 'UPSTREAM_REDIRECT');
    }
    const outgoing = { ...cors };
    for (const name of ['content-type', 'x-correlation-id']) {
      if (remote.headers[name]) outgoing[name] = remote.headers[name];
    }
    response.writeHead(remote.statusCode || 502, outgoing);
    remote.on('error', () => response.destroy());
    remote.pipe(response);
  });
  forwarded.setTimeout(15000, () => forwarded.destroy());
  forwarded.on('error', () => {
    if (!response.headersSent) fail(502, 'UPSTREAM_UNAVAILABLE');
    else response.destroy();
  });
  request.on('aborted', () => forwarded.destroy());
  request.pipe(forwarded);
});

server.listen(config.proxyPort, '127.0.0.1', () => {
  process.stdout.write(`Development API proxy ready on port ${config.proxyPort}\n`);
});
