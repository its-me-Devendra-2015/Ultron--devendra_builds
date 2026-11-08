# ULTRON Mobile

Flutter companion + independent client for ULTRON 1.3.3. This directory is intentionally isolated from the existing Electron desktop app.

## Modes

- **Companion:** connects to a running ULTRON desktop bridge on the same trusted network.
- **Independent:** connects to the hosted ULTRON LiveKit agent/backend without requiring the PC to be online.

Both modes use the same LiveKit call UI. The backend must route requests to the existing ULTRON model/provider router; do not create a second unrelated assistant brain.

## Current status

This is the first isolated mobile foundation: Flutter app shell, LiveKit room/call client, backend URL configuration, and integration contract. The LiveKit Python agent currently described in the developer's local workspace (`src/agent.py`, `browser.py`, `prompts.py`, `tools.py`) is not present in this GitHub repository snapshot. Therefore this branch does not overwrite or pretend to integrate those files. Once that agent source is pushed, wire its existing `AgentServer` into the token/session backend and preserve `agent_name="my-agent"`.

## Run

1. Install Flutter stable and Android Studio / Xcode (iOS builds require macOS).
2. From this folder run `flutter create --platforms=android,ios .` once to generate the native platform runners.
3. Run `flutter pub get`.
4. Set `ULTRON_API_BASE_URL` in `.env`.
5. Run `flutter run`.

## Backend contract

- `GET /health` -> `{"status":"ok"}`
- `POST /api/mobile/session` with `{"mode":"companion"|"independent"}` -> `{"server_url":"wss://...","room_name":"...","participant_token":"...","expires_at":"..."}`

The API must authenticate the user before issuing short-lived room tokens. Never embed LiveKit API secrets in the mobile app. The backend should dispatch the existing `my-agent` worker to the room and enforce one authorized participant/session.

## Safety and desktop compatibility

- No existing desktop files are changed by this branch.
- Do not expose the desktop bridge directly to the public internet.
- Require pairing + a revocable device token for companion mode.
- Destructive PC actions must require explicit confirmation in the app and on the desktop.
- Use HTTPS/WSS in production.
