# ULTRON 1.3.3 — Advanced upgrade status

## Branch
`upgrade/1.3.3-advanced-desktop`

## Preservation baseline inspected
- Electron entry point: `main.js`
- Local Node HTTP backend: `server.js`
- Single-page renderer: `index.html`
- Existing AI integrations: Gemini, Ollama, Fish Audio
- Existing chat history: JSONL file in the application data directory
- Existing screen scan: renderer `getDisplayMedia` followed by `/api/vision`

## Findings
- Electron already enables `contextIsolation`, `sandbox`, and disables `nodeIntegration`.
- Assistant messages are currently escaped as plain text; Markdown is not rendered.
- Screen capture uses browser media APIs rather than Electron's `desktopCapturer`.
- The GitHub connector exposed individual files but not a recursive repository tree. Inspected entry points and known configuration/installer files; this is not a claim that every repository path was enumerated.
- No automated test script was visible in the inspected package configuration.

## Milestones
- [x] Baseline entry points and integrations inspected.
- [x] Isolated upgrade branch created.
- [ ] Secure Electron desktop-capture bridge and explicit sharing controls.
- [ ] Windows DPAPI credential vault and exact-domain release.
- [ ] Guarded Windows automation and emergency stop.
- [ ] Markdown chat rendering and personality modes.
- [ ] Integration and regression verification on Windows.

## Verification policy
Features are not marked complete until connected and tested. GitHub-side edits cannot verify local Windows UI Automation, DPAPI, screen-capture permissions, or user API keys; those require running this branch on Windows.
