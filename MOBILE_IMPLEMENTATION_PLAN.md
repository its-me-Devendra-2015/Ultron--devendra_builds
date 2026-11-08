# ULTRON Mobile implementation plan

## Product decisions

- Operating modes: companion + independent.
- Platforms: Android + iOS.
- AI brain: reuse the existing ULTRON model router and tools.
- Calling: LiveKit audio first, optional video from the same room.
- Desktop compatibility: no changes to existing desktop files in this mobile foundation branch.

## Current repository finding

The GitHub repository is ULTRON desktop v1.3.3 (Electron). Its current `package.json` targets Electron and its README describes a Windows desktop application. The LiveKit Python agent discussed in the local development workspace (`src/agent.py`, `browser.py`, `prompts.py`, `tools.py`) is not in this repository snapshot. The mobile app is therefore added in new directories and calls a documented backend contract; the agent integration is not falsely represented as complete.

## Phases

1. **Mobile foundation** — Flutter app shell, crimson ULTRON theme, mode selector, configuration.
2. **LiveKit calling** — short-lived backend token, voice room join, mute, camera toggle, end call.
3. **Shared AI brain** — extract/reuse the current provider/model router and prompt/tool definitions as a shared Python package. Keep the desktop's existing import paths working through compatibility wrappers.
4. **Agent dispatch** — dispatch the existing `my-agent` worker to each authenticated mobile room; verify voice replies and interruptions.
5. **Companion bridge** — secure pairing, outbound desktop connection, online state, allow-listed PC tools, per-action confirmation for sensitive operations.
6. **Independent hosting** — deploy the same agent/router in a hosted worker. Do not assume a PC-local Ollama model is available when the PC is offline.
7. **Video and screen sharing** — LiveKit camera tracks first; screen share only with explicit user consent and platform support.
8. **Hardening and release** — token expiry, device revocation, rate limiting, privacy controls, Android permissions, iOS entitlements, CI builds, physical-device testing.

## Acceptance checks

- Existing desktop launch/build flow remains unchanged.
- Flutter app starts on Android and iOS.
- Companion mode refuses connection unless the paired desktop is authenticated and online.
- Independent mode works with the PC powered off.
- Mobile token is short-lived and contains only room-scoped grants.
- Agent joins and responds using the same ULTRON model router and persona.
- Mic mute, camera enable/disable, and end-call work on physical devices.
- No API keys/secrets are bundled in the mobile app.
- Destructive PC actions require explicit confirmation.
