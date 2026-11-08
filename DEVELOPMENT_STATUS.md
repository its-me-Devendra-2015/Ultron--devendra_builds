# ULTRON 1.3.3 — Advanced upgrade status

## Branch
`upgrade/1.3.3-advanced-desktop`

## Preservation baseline inspected
- Electron entry point: `main.js`
- Local Node HTTP backend: `server.js`
- Single-page renderer: `index.html`
- Launcher: `app.js`
- Configuration and packaging: `package.json`, `.env.example`, `build-exe.bat`, installer NSIS script
- Existing integrations: Gemini, Ollama, Fish Audio, Gmail read-only, news/research and saved chat history
- Existing screen scan: renderer `getDisplayMedia` followed by `/api/vision`

The GitHub connector exposed individual file reads but not a recursive repository tree. The files listed above were inspected; this is not a claim that every repository path, asset or installer helper was exhaustively enumerated.

## Implemented in this branch
- [x] Isolated upgrade branch; `main` remains unchanged.
- [x] Added a restricted Electron preload bridge and native display/window source enumeration through `desktopCapturer`.
- [x] Added screen selection, live preview, pause/stop, persistent in-app sharing indicator, and user-confirmed screenshot analysis.
- [x] Added Windows UI Automation helpers for visible-window enumeration, named-control inspection/invocation, allowlisted app launch, graceful close, text input and validated keyboard shortcuts.
- [x] Added approval prompts for visible UI actions and an emergency stop/resume mechanism.
- [x] Added Windows DPAPI-backed encrypted credential storage, exact HTTPS hostname matching, listing and deletion. Password release is user-confirmed and copies to clipboard.
- [x] Added Normal, Sarcastic, British Butler and playful Roast personality modes with a non-abusive system instruction.
- [x] Added safe Markdown rendering for paragraphs, headings, lists, tables, quotes, inline code and fenced code; HTML is escaped, code copy controls are provided, and prior assistant history uses the renderer.
- [x] Added Node security tests and a Windows GitHub Actions workflow for syntax and regression checks.
- [x] Updated Electron packaging file list for the preload and new modules.
- [x] Added provider-neutral Ollama model discovery and a Settings picker for installed Qwen, Kimi, DeepSeek, Llama, Mistral, Gemma, Phi and other chat models.
- [x] Added explicit model selection with installed-model validation and regression tests for Qwen/Kimi family detection.
- [x] Expanded Gmail from a one-shot unread summary into a dedicated read-only inbox: Gmail search queries, Inbox/Unread/Starred/Sent/Attachments/last-7-days filters, 20-message pages, sender/subject/date/snippets, and a full message reader with plain-text extraction. Existing OAuth `gmail.readonly` scope is preserved; no send/delete/archive/mark-read permissions were added.
- [x] Gmail now has a direct **Sign in with Google** action in the Gmail tab; OAuth client credentials are treated as app-maintainer configuration, not something Gmail users should be asked to enter. The sign-in button opens Google's OAuth page when the app's OAuth client is configured.

## Known incomplete requirements
- [ ] Website login-page recognition and automatic form autofill are not implemented. The vault currently supports secure storage, exact-domain-gated reveal and clipboard copy; it does not inject credentials into arbitrary websites.
- [ ] Credential edit and vault lock/unlock UX are not complete.
- [ ] Multi-step task planning, window switching, broad file/folder navigation and browser navigation are not complete.
- [ ] True token streaming is not implemented; current AI backend returns completed responses.
- [ ] End-to-end testing of Gemini, Ollama/Gemma, Fish Audio, DPAPI, Windows UI Automation and Electron capture has not been performed on the target Windows PC.
- [ ] GitHub Actions results are pending; no workflow run has been returned for the latest upgrade commit yet.
- [ ] The Ollama model picker and inference requests still need runtime verification against the models installed on the user's Windows PC.

## Security notes
- Secrets are not added to AI chat messages or assistant history.
- Screen capture requires explicit source selection and confirmation; only a separately confirmed screenshot is submitted to vision.
- Automation actions are limited to supported operations, with user confirmation in the UI and an emergency stop.
- DPAPI encryption is Windows-user scoped; the vault requires the same Windows user profile to decrypt.
- Do not use this branch for unattended or hidden screen capture.

## Next milestones
1. Complete secure login-page recognition/autofill and vault lock/edit UX.
2. Add window switching, folder/browser navigation and multi-step task execution with per-step approvals.
3. Implement actual streaming transport and renderer updates.
4. Run the Windows CI workflow, fix failures, then test the desktop app on Windows with configured integrations.
5. Update this file with actual test evidence before declaring release-ready.
