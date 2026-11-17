'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { SessionSyncClient, normalizeBaseUrl } = require('../core/session-client');

test('desktop pairing stores the revocable device credential and shared session ID', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ultron-session-'));
  const calls = [];
  const sessionId = '11111111-1111-4111-8111-111111111111';
  const fakeFetch = async (url, options) => {
    calls.push({ url, options });
    return {
      ok: true,
      json: async () => ({
        device_token: 'udv_test-secret',
        device_id: 'device-1',
        owner_uid: 'user-1',
        session_id: sessionId,
      }),
    };
  };
  const tokenPath = path.join(dir, '.device.json');
  const client = new SessionSyncClient({
    baseUrl: 'https://example.invalid',
    tokenPath,
    fetch: fakeFetch,
  });
  const result = await client.pair('ABCD1234');
  assert.equal(result.paired, true);
  assert.equal(result.sessionId, sessionId);
  assert.equal(client.status().paired, true);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, 'https://example.invalid/api/devices/pair');
  assert.equal(JSON.parse(fs.readFileSync(tokenPath, 'utf8')).deviceToken, 'udv_test-secret');
  assert.equal(client.status().deviceToken, undefined);
  fs.rmSync(dir, { recursive: true, force: true });
});

test('desktop event sync sends the device bearer token and canonical envelope', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ultron-session-'));
  const calls = [];
  const sessionId = '22222222-2222-4222-8222-222222222222';
  const fakeFetch = async (url, options) => {
    calls.push({ url, options });
    return {
      ok: true,
      json: async () => ({
        device_token: 'udv_test-secret',
        device_id: 'device-2',
        owner_uid: 'user-2',
        session_id: sessionId,
      }),
    };
  };
  const client = new SessionSyncClient({
    baseUrl: 'https://example.invalid',
    tokenPath: path.join(dir, '.device.json'),
    fetch: fakeFetch,
  });
  await client.pair('ZXCV1234');
  await client.append('message.user', 'desktop', { text: 'hello' }, 'request-1');
  const eventRequest = calls[1];
  assert.equal(eventRequest.options.headers.Authorization, 'Bearer udv_test-secret');
  const event = JSON.parse(eventRequest.options.body);
  assert.equal(event.session_id, sessionId);
  assert.equal(event.event_type, 'message.user');
  assert.equal(event.request_id, 'request-1');
  assert.equal(event.payload.text, 'hello');
  fs.rmSync(dir, { recursive: true, force: true });
});

test('desktop event sync is skipped when the device is not paired', async () => {
  const client = new SessionSyncClient({
    baseUrl: 'https://example.invalid',
    tokenPath: path.join(os.tmpdir(), 'ultron-no-device-file'),
  });
  assert.deepEqual(await client.append('message.user', 'desktop', { text: 'ignored' }), {
    paired: false,
    skipped: true,
  });
});

test('remote session endpoints require HTTPS while loopback development is allowed', () => {
  assert.throws(() => normalizeBaseUrl('http://api.example.com'), /HTTPS/);
  assert.equal(normalizeBaseUrl('http://127.0.0.1:8000'), 'http://127.0.0.1:8000');
  assert.equal(normalizeBaseUrl('https://api.example.com/'), 'https://api.example.com');
});
