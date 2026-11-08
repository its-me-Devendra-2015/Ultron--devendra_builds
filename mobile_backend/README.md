# ULTRON Mobile backend

Separate service boundary for the Flutter client. It does not modify the existing Electron desktop server or the LiveKit agent.

## Run locally

1. Create a Python virtual environment.
2. Install `pip install -r requirements.txt`.
3. Copy `.env.example` to `.env` and configure LiveKit credentials plus a long random `ULTRON_MOBILE_BEARER_TOKEN`.
4. Start with `uvicorn app:app --host 127.0.0.1 --port 8787`.

## API

- `GET /health` returns service health.
- `POST /api/mobile/session` accepts `{"mode":"independent"}` or `{"mode":"companion"}`, requires `Authorization: Bearer <device-token>`, creates a unique room, issues a 10-minute room-scoped participant token, and explicitly dispatches `ULTRON_AGENT_NAME` (default `my-agent`).

The Flutter app stores the device token using platform secure storage. The current bootstrap uses a manually provisioned bearer token; production should replace it with real device pairing/OAuth and per-device revocation. Do not use one shared token across users.

## Companion mode

Companion mode is intentionally disabled by default. Enable it only after implementing a mutually authenticated desktop bridge and an online/pairing check. Do not expose the desktop HTTP server directly to the public internet. Use an outbound desktop connection or private tunnel, strict tool allow-lists, audit logs, and explicit confirmation for destructive actions.

## Existing AI brain

The current GitHub snapshot contains the ULTRON 1.3.3 Electron desktop application. The local LiveKit agent modules (`src/agent.py`, `browser.py`, `prompts.py`, `tools.py`) discussed in development are not present in this repository snapshot. Deploy the same agent code and reuse its existing prompt, tools, and provider/model router; do not create a separate AI persona or duplicate model-routing implementation.

Independent mode requires that shared agent/model router to be deployed. A model running only on a powered-off PC cannot serve independent mode.
