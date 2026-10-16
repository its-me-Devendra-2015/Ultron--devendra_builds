# ULTRON v1.1: what's new

## Install (the easy way)
1. Run **ULTRON-Setup-1.3.3.exe**. A short splash appears, then the custom dark setup wizard: rounded, with a step rail on the left (Welcome, Location, Services, Install, Done).
   It installs for your user only (no admin rights) and can add a Desktop shortcut.
   Windows may show a blue "Windows protected your PC" screen because the installer is not code-signed. Click **More info > Run anyway**.
2. On the **Services** step paste your Gemini key, Fish Audio key and voice ID (all optional). They are saved to `%APPDATA%\ULTRON\.env`. If settings from an earlier install exist, that step is locked and they are kept.
3. The last step shows whether Ollama is installed. For offline mode install **Ollama** from https://ollama.com/download and run `ollama pull gemma4:e2b` once.
   ULTRON detects whichever Gemma you already have (it prefers gemma4:e2b, then gemma4:e4b, then gemma3).

Uninstall from Windows **Settings > Apps > ULTRON** (or the Start Menu shortcut). It opens a matching dark dialog, removes only the files the installer wrote, and asks whether to also delete your keys and chat history.
If the wizard window cannot start on some PC, the installer falls back to a silent install with defaults and tells you to add keys in ULTRON > Settings.

## Automatic online / offline
- Internet works: replies come from Gemini (or whichever cloud AI you configured).
- Internet down or the cloud fails: ULTRON switches to your local Gemma through Ollama by itself, including screen scans (Gemma is multimodal) and the browser voice instead of Fish Audio.
- Top-right chip shows the active brain. **Settings > Brain** lets you force Cloud only or Local only.
- The first local reply after a cold start is slower while the model loads. Set `WARM_LOCAL=1` in `.env` to keep it preloaded.

## Commands added
| Say or type | What happens |
|---|---|
| `brief me`, `what's going on`, `world news` | Pulls live headlines (BBC, CNBC, NYT, Al Jazeera), then speaks a short brief |
| `finance news`, `how are the markets` | Same with finance feeds (CNBC, Bloomberg, Reuters, MarketWatch, NYT Business) |
| `open world monitor`, `open finance monitor` | Asks, then opens worldmonitor.app / finance.worldmonitor.app |
| `summarize https://...`, `read https://...` | Fetches the page and summarizes it |
| `summarize: <text>`, `explain python code: <code>` | Summary / step by step explanation |
| `word count: <text>`, `format json: {...}` | Local, instant |
| `volume up/down`, `mute`, `lock the pc` | Instant system actions (lock asks first) |
| `search for <topic>`, `Google <topic>`, `research <topic>` | Searches with Gemini's Google Search grounding API and returns an answer with source links (requires `GEMINI_API_KEY`) |
| `check my Gmail`, `read my unread emails` | Summarizes unread inbox mail after connecting Gmail in Settings; requires a Google OAuth desktop client and requests read-only access |
| `clear chat history` | Deletes the saved conversation |
| `hi`, `who are you`, `thanks` | Instant answers, no AI call |

Chat history is now saved to disk and restored when you reopen ULTRON.

## Building the installer yourself
- The custom installer and uninstaller shown in the supplied reference recordings are built with `installer\build-custom-installer.bat` (needs Node 20+ and NSIS). Output: `ULTRON-Setup-1.3.3.exe`.

