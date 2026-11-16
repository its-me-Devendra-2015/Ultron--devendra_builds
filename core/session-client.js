const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class SessionSyncClient {
  constructor(options = {}) {
    this.baseUrl = String(options.baseUrl || process.env.ULTRON_SESSION_API_URL || '').replace(/\/+$/, '');
    this.tokenPath = options.tokenPath || path.join(process.env.ULTRON_HOME || __dirname, '.ultron-device.json');
    this.fetch = options.fetch || globalThis.fetch;
    this.state = null;
    try {
      const value = JSON.parse(fs.readFileSync(this.tokenPath, 'utf8'));
      if (value && typeof value.deviceToken === 'string' && typeof value.sessionId === 'string') this.state = value;
    } catch {}
  }

  get paired() { return !!(this.state && this.state.deviceToken && this.state.sessionId); }

  async request(route, options = {}, token = '') {
    if (!this.baseUrl) throw new Error('Set ULTRON_SESSION_API_URL before pairing ULTRON Desktop.');
    const response = await this.fetch(this.baseUrl + route, {
      ...options,
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
    const session = await this.request('/api/sessions', {
      method: 'POST',
      body: JSON.stringify({ title: deviceLabel + ' session' }),
    }, paired.device_token);
    const state = {
      deviceToken: paired.device_token,
      deviceId: paired.device_id,
      ownerUid: paired.owner_uid,
      sessionId: session.session_id,
    };
    fs.mkdirSync(path.dirname(this.tokenPath), { recursive: true });
    fs.writeFileSync(this.tokenPath, JSON.stringify(state), { mode: 0o600 });
    this.state = state;
    return { paired: true, sessionId: state.sessionId, ownerUid: state.ownerUid };
  }

  async append(eventType, source, payload) {
    if (!this.paired) return { paired: false, skipped: true };
    const event = {
      protocol_version: '1.0',
      event_id: crypto.randomUUID(),
      session_id: this.state.sessionId,
      event_type: eventType,
      occurred_at: new Date().toISOString(),
      source,
      payload: payload || {},
    };
    return this.request('/api/sessions/' + encodeURIComponent(this.state.sessionId) + '/events', {
      method: 'POST',
      body: JSON.stringify(event),
    }, this.state.deviceToken);
  }

  status() {
    return { paired: this.paired, sessionId: this.state?.sessionId || null, ownerUid: this.state?.ownerUid || null };
  }
}

module.exports = { SessionSyncClient };
