# ULTRON 2.0 — Cross-platform foundation

This folder defines the first compatibility layer for the existing desktop app and ULTRON Mobile.

## First module: event envelope

The canonical schema is `shared/ultron_protocol.json`. Desktop code can use `core/protocol.js`; mobile will mirror the same field names and validation rules in Dart.

Every event carries:
- `protocol_version`: contract version, currently `1.0`.
- `event_id`: unique event identifier.
- `session_id`: shared conversation/session identifier.
- `request_id`: optional correlation ID for request/response pairs.
- `event_type`: namespaced event name.
- `occurred_at`: ISO-8601 timestamp.
- `source`: `desktop`, `mobile`, `backend`, or `agent`.
- `payload`: event-specific object.

Supported event types: `session.started`, `session.ended`, `message.user`, `message.assistant`, `assistant.state`, `tool.started`, `tool.completed`, `tool.failed`, `audio.state`, `system.status`, and `error`.

Assistant states: `idle`, `listening`, `thinking`, `speaking`, `acting`, `offline`, `error`.

## Compatibility and safety

- Keep the desktop's existing localhost API and provider configuration intact.
- Mobile must never receive Ollama, cloud-provider, Firebase Admin, or LiveKit API secrets.
- A client event is data, not authorization. The backend must independently authorize every privileged operation.
- New event types require a protocol versioning decision and tests on both clients.
- The contract is transport-neutral: it can be carried over HTTPS, WebSocket, or LiveKit data messages.

## Verification

Run the desktop protocol tests with `npm test`. The matching Dart model and tests live in the ULTRON Mobile repository under `mobile/lib/core` and `mobile/test/core`.
