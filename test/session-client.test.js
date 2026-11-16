const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { SessionSyncClient } = require('../core/session-client');

test('desktop pairing stores device credential locally and creates a session', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ultron-session-'));
  const calls = [];
  const fakeFetch = async (url, options) => {
    calls.push({ url, options });
    const data = url.endsWith('/api/devices/pair')
      ? { device_token: 'udv_test-secret', device_id: 'device-1', owner_uid: 'user-1' }
      : { session_id: '11111111-1111-4111-8111-111111111111' };
    return { ok: true, json: async () => data };
  };
  const client = new SessionSyncClient({ baseUrl: 'https://example.invalid', tokenPath: path.join(dir, '.device.json'), fetch: fakeFetch });
  const result = await client.pair('ABCD1234');
  assert.equal(result.paired, true);
  assert.equal(client.status().paired, true);
  assert.equal(calls.length, 2);
  assert.equal(JSON.parse(fs.readFileSync(path.join(dir, '.device.json'), 'utf8')).deviceToken, 'udv_test-secret');
  fs.rmSync(dir, { recursive: true, force: true });
});

test('desktop event sync is skipped when the device is not paired', async () => {
  const client = new SessionSyncClient({ baseUrl: 'https://example.invalid', tokenPath: path.join(os.tmpdir(), 'ultron-no-device-file') });
  assert.deepEqual(await client.append('message.user', 'desktop', { text: 'hello' }), { paired: false, skipped: true });
});
