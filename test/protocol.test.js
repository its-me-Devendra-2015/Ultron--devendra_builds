'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createEnvelope, validateEnvelope, ASSISTANT_STATES } = require('../core/protocol');

test('creates a valid cross-platform event envelope', () => {
  const event = createEnvelope({
    sessionId: 'session-123',
    eventType: 'assistant.state',
    source: 'desktop',
    payload: { state: 'thinking' }
  });
  assert.equal(validateEnvelope(event).valid, true);
  assert.equal(event.protocol_version, '1.0');
  assert.equal(event.payload.state, 'thinking');
});

test('rejects unsupported event types and invalid payloads', () => {
  assert.throws(() => createEnvelope({
    sessionId: 'session-123', eventType: 'unknown.event', source: 'desktop'
  }), /eventType/);
  assert.throws(() => createEnvelope({
    sessionId: 'session-123', eventType: 'message.user', source: 'desktop', payload: []
  }), /payload/);
});

test('validator rejects malformed envelopes and accepts the defined assistant states', () => {
  assert.equal(validateEnvelope({}).valid, false);
  for (const state of ['idle', 'listening', 'thinking', 'speaking', 'acting', 'offline', 'error']) {
    assert.equal(ASSISTANT_STATES.has(state), true);
  }
});
