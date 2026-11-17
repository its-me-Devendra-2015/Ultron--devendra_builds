'use strict';

const fs = require('fs');
const path = require('path');
const { createEnvelope } = require('./protocol');

function normalizeBaseUrl(value) {
  const raw = String(value || '').trim();
  if (!raw) return '';
  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    throw new Error('ULTRON_SESSION_API_URL must be a valid absolute URL.');
  }
  const hostname = parsed.hostname.replace(/^\[|\]$/g, '').toLowerCase();
  const loopback = ['localhost', '127.0.0.1', '::1'].includes(hostname);
  if (parsed.protocol !== 'https:' && !(parsed.protocol === 'http:' && loopback)) {
    throw new Error('The ULTRON session service must use HTTPS (HTTP is allowed only on loopback).');
  }
  if (parsed.username || parsed.password || parsed.hash) {
    throw new Error('ULTRON_SESSION_API_URL must not contain credentials or a fragment.');
  }
  return parsed.toString().replace(/\/+$/, '');
}

class SessionSyncClient {
  constructor(options = {}) {
    this.baseUrl = normalizeBaseUrl(options.baseUrl ?? process.env.ULTRON_SESSION_API_URL ?? '');
    this.tokenPath = options.tokenPath || path.join(process.env.ULTRON_HOME || __dirname, '.ultron-device.json');
    this.fetch = options.fetch || globalThis.fetch;
    this.state = null;
    try {
      const value = JSON.parse(fs.readFileSync(this.tokenPath, 'utf8'));
      if (value && typeof value.deviceToken === 'string' &&
          typeof value.sessionId === 'string' && typeof value.deviceId === 'string') {
        this.state = value;
      }
    } catch {}
  }

  get paired() {
    return !!(this.state && this.state.deviceToken && this.state.sessionId && this.state.deviceId);
  }

  async request(route, options = {}, token = '') {
    if (!this.baseUrl) throw new Error('Set ULTRON_SESSION_API_URL before pairing ULTRON Desktop.');
    const response = await this.fetch(this.baseUrl + route, {
      ...options,
      redirect: 'error',
      headers: {
        ...(options.headers || {}),
        ...(token ? { Authorization: 'Bearer ' + token } : {}),
        'Content-Type': 'application/json',
      },
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.detail || data.error || 'Session service HTTP ' + response.status);
    return data;
  }

  async pair(code, deviceLabel = 'ULTRON Desktop') {
    const paired = await this.request('/api/devices/pair', {
      method: 'POST',
      body: JSON.stringify({ code: String(code || '').trim().toUpperCase(), device_label: deviceLabel }),
    });
    if (!paired.device_token || !paired.device_id || !paired.owner_uid || !paired.session_id) {
      throw new Error('The session service returned an incomplete pairing response. Update the backend and try again.');
    }
    const state = {
      deviceToken: paired.device_token,
      deviceId: paired.device_id,
      ownerUid: paired.owner_uid,
      sessionId: paired.session_id,
    };
    fs.mkdirSync(path.dirname(this.tokenPath), { recursive: true });
    fs.writeFileSync(this.tokenPath, JSON.stringify(state), { mode: 0o600 });
    this.state = state;
    return { paired: true, sessionId: state.sessionId, ownerUid: state.ownerUid };
  }

  async append(eventType, source, payload, requestId) {
    if (!this.paired) return { paired: false, skipped: true };
    const event = createEnvelope({
      sessionId: this.state.sessionId,
      eventType,
      source,
      payload: payload || {},
      requestId,
    });
    return this.request('/api/sessions/' + encodeURIComponent(this.state.sessionId) + '/events', {
      method: 'POST',
      body: JSON.stringify(event),
    }, this.state.deviceToken);
  }

  status() {
    return {
      paired: this.paired,
      sessionId: this.state?.sessionId || null,
      ownerUid: this.state?.ownerUid || null,
    };
  }
}

module.exports = { SessionSyncClient, normalizeBaseUrl };
