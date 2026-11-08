# ULTRON Mobile backend integration

This backend is deliberately a separate service boundary. Do not modify the existing desktop Electron server or agent just to make mobile work.

## Required API

Implement `POST /api/mobile/session`:
1. Authenticate a paired device / signed-in user.
2. Validate `mode` as `companion` or `independent`.
3. For companion mode, verify the paired desktop is online and authorized.
4. Create a unique room name and short-lived participant JWT using server-side LiveKit API credentials.
5. Dispatch the existing LiveKit agent named `my-agent` into that room.
6. Return `server_url`, `room_name`, `participant_token`, and ISO-8601 `expires_at`.

The current repository contains the ULTRON 1.3.3 Electron app, but not the local LiveKit agent files `src/agent.py`, `browser.py`, `prompts.py`, and `tools.py`. Integration must happen after those files are added to the repository or supplied to the backend workspace. Reuse the existing model router and prompt/tool modules; do not duplicate the assistant brain.

## Environment variables (server only)

- `LIVEKIT_URL`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`
- `ULTRON_SESSION_SIGNING_SECRET`
- `ULTRON_DESKTOP_BRIDGE_URL` (private network/service address; never accept arbitrary URLs from clients)

Never ship API secrets to Flutter. Enforce token expiry, room grants, origin/rate limits, pairing revocation, and audit logs. Companion mode should use an outbound authenticated desktop connection or a private tunnel; do not expose the desktop HTTP server directly to the public internet.

## Independent mode

Run the same ULTRON agent/model-router code in a hosted worker with its required provider credentials. Independent mode cannot reach a model running only on the user's offline PC. If the existing model router has Ollama-only providers, those are available only when the PC/Ollama host is online and securely reachable.
