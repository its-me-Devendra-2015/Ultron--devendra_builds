'use strict';

const { randomUUID } = require('node:crypto');

const PROTOCOL_VERSION = '1.0';
const SOURCES = new Set(['desktop', 'mobile', 'backend', 'agent']);
const EVENT_TYPES = new Set([
  'session.started', 'session.ended',
  'message.user', 'message.assistant',
  'assistant.state',
  'tool.started', 'tool.completed', 'tool.failed',
  'audio.state', 'system.status', 'error'
]);
const ASSISTANT_STATES = new Set([
  'idle', 'listening', 'thinking', 'speaking', 'acting', 'offline', 'error'
]);

function createEnvelope({ sessionId, eventType, source, payload = {}, requestId, occurredAt = new Date() }) {
  if (typeof sessionId !== 'string' || !sessionId.trim()) throw new TypeError('sessionId is required');
  if (!EVENT_TYPES.has(eventType)) throw new TypeError('Unsupported eventType');
  if (!SOURCES.has(source)) throw new TypeError('Unsupported source');
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) throw new TypeError('payload must be an object');
  const date = occurredAt instanceof Date ? occurredAt : new Date(occurredAt);
  if (Number.isNaN(date.getTime())) throw new TypeError('occurredAt must be a valid date');

  const envelope = {
    protocol_version: PROTOCOL_VERSION,
    event_id: randomUUID(),
    session_id: sessionId,
    event_type: eventType,
    occurred_at: date.toISOString(),
    source,
    payload
  };
  if (requestId !== undefined) {
    if (typeof requestId !== 'string' || !requestId.trim()) throw new TypeError('requestId must be a non-empty string');
    envelope.request_id = requestId;
  }
  return envelope;
}

function validateEnvelope(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return { valid: false, error: 'Envelope must be an object' };
  const required = ['protocol_version', 'event_id', 'session_id', 'event_type', 'occurred_at', 'source', 'payload'];
  for (const key of required) if (!(key in value)) return { valid: false, error: 'Missing ' + key };
  if (value.protocol_version !== PROTOCOL_VERSION) return { valid: false, error: 'Unsupported protocol_version' };
  if (typeof value.event_id !== 'string' || !value.event_id.trim()) return { valid: false, error: 'Invalid event_id' };
  if (typeof value.session_id !== 'string' || !value.session_id.trim()) return { valid: false, error: 'Invalid session_id' };
  if (!EVENT_TYPES.has(value.event_type)) return { valid: false, error: 'Unsupported event_type' };
  if (!SOURCES.has(value.source)) return { valid: false, error: 'Unsupported source' };
  if (!value.payload || typeof value.payload !== 'object' || Array.isArray(value.payload)) return { valid: false, error: 'payload must be an object' };
  if (typeof value.occurred_at !== 'string' || Number.isNaN(Date.parse(value.occurred_at))) return { valid: false, error: 'Invalid occurred_at' };
  if (value.request_id !== undefined && (typeof value.request_id !== 'string' || !value.request_id.trim())) return { valid: false, error: 'Invalid request_id' };
  return { valid: true };
}

module.exports = { PROTOCOL_VERSION, SOURCES, EVENT_TYPES, ASSISTANT_STATES, createEnvelope, validateEnvelope };
