# 🔴 ULTRON — Personal AI Assistant

**Your Personal AI Command Center.**

ULTRON is a futuristic personal AI assistant designed to bring intelligent conversations, desktop interaction, file management, and productivity tools into one unified application.

Inspired by the cinematic interfaces of Iron Man, ULTRON combines a sleek dark dashboard, crimson-red holographic visuals, and a **hybrid AI architecture** that can use cloud-based AI providers or local AI models powered by Ollama.

**Online AI when you need it. Local AI when you want privacy and offline access.**

![ULTRON](https://img.shields.io/badge/ULTRON-Personal%20AI%20Assistant-crimson?style=for-the-badge)
![AI](https://img.shields.io/badge/AI-Hybrid%20%7C%20Cloud%20%7C%20Local-red?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-In%20Development-orange?style=for-the-badge)

---

## ✨ Features

- 🤖 **AI Assistant** — Interact with supported AI models through a unified interface.
- 🔀 **Hybrid AI Architecture** — Choose between cloud-based AI and locally hosted models.
- ☁️ **Online AI Mode** — Connect supported cloud providers using your API keys.
- 📴 **Offline AI Mode** — Run downloaded local models using Ollama without an internet connection.
- 🔴 **Futuristic Dashboard** — Dark backgrounds, crimson-red accents, neon borders, and sci-fi-inspired HUD elements.
- ⚙️ **Settings** — Configure supported AI providers, model names, and application preferences.
- 📁 **File Management** — Access supported file-related tools.
- 🧰 **Productivity Tools** — Bring supported utilities and assistant features together.
- 🖥️ **Windows Executable** — Build the desktop application using `build-exe.bat`.
- 🔐 **Local AI Privacy** — Process prompts locally when using Ollama, subject to the application's implementation.

*Feature availability depends on the current source code, configured providers, and installed integrations.*

---

## 🧠 Hybrid AI System

ULTRON is designed to support two complementary AI modes.

<details>
<summary><strong>☁️ Online AI Mode — Cloud Providers</strong></summary>

Use compatible cloud AI services for models hosted by external providers.

**Setup:**

1. Open ULTRON.
2. Navigate to **Settings**.
3. Scroll down to the API configuration section.
4. Select your supported AI provider.
5. Enter the corresponding API key.
6. Select a supported model, if required.
7. Save your settings and test a conversation.

**Requirements:**

- Internet connection.
- A valid API key for providers that require authentication.
- Provider access and any required billing or usage allowance.

**Advantages:**

- Access to supported cloud-hosted models.
- No need to download large model files locally.
- Model capabilities depend on the selected provider and service.

</details>

<details>
<summary><strong>📴 Offline AI Mode — Ollama</strong></summary>

Ollama allows compatible AI models to run locally on your computer. Once Ollama and a model are installed, inference can work without an internet connection.

**Advantages:**

- No cloud API key required for local inference.
- Local processing of prompts.
- No cloud inference charges for local model usage.
- Works without internet after the required downloads are complete.
- More control over where your conversation data is processed.

**Requirements:**

- Ollama installed and running.
- A compatible model downloaded locally.
- Enough disk space and memory for the selected model.
- ULTRON configured to communicate with Ollama.

</details>

### 🔀 Switching Between AI Modes

When both integrations are implemented, users should be able to switch between cloud and local AI through ULTRON's Settings.

| Capability | Online AI | Ollama Offline |
|---|---|---|
| Internet required for inference | Yes | No, after setup |
| Cloud API key | Usually required | Not required |
| Model runs locally | No | Yes |
| Cloud inference charges | May apply | No |
| Local hardware required for inference | Minimal beyond the app | Depends on the model |
| Online-only tools | Available when configured | Require internet independently |

**Important:** A hybrid design does not automatically provide offline support. The application must implement Ollama integration, provider selection, and local request handling.

---

## 📴 Setting Up Ollama Offline Mode

### Step 1 — Install Ollama

Download Ollama for Windows from the official website:

https://ollama.com/download

Install the application and start the Ollama service.

### Step 2 — Download a Model

Open PowerShell or Command Prompt and run:

```powershell
ollama pull llama3.2:3b
```

Wait until the model download completes. This step requires an internet connection.

The `llama3.2:3b` model is an example of a relatively small local model. Actual performance depends on your computer's available memory, CPU, and supported acceleration.

### Step 3 — Test the Model

Run:

```powershell
ollama run llama3.2:3b
```

Enter a prompt and verify that the model responds.

To exit the conversation, enter:

```text
/bye
```

### Step 4 — Configure ULTRON

1. Launch ULTRON.
2. Open **Settings**.
3. Scroll to the AI provider configuration section.
4. Select **Ollama** or **Local AI**, if available.
5. Set the Ollama endpoint to:

   `http://localhost:11434`

6. Set the model name to:

   `llama3.2:3b`

7. Save your configuration, if required.
8. Test a conversation.

These settings require actual Ollama support in the application. If Ollama is not available in Settings, the source code must be updated before this workflow will work.

### Step 5 — Use ULTRON Without Internet

1. Download your desired model in advance.
2. Confirm that it responds successfully.
3. Keep the Ollama service running.
4. Disconnect from the internet.
5. Open ULTRON and select the local AI provider.
6. Send a test prompt.

Local AI inference should continue to work, provided that ULTRON and Ollama are configured correctly and neither depends on a cloud service for that operation.

**Offline limitations:** Web search, cloud AI, online APIs, remote content, and other internet-dependent features will not work without connectivity.

---

## 📥 Installation Guide

### Step 1 — Download the Source Code

Clone the repository:

```powershell
git clone https://github.com/its-me-Devendra-2015/Ultron--devendra_builds.git
```

Navigate into the project folder:

```powershell
cd Ultron--devendra_builds
```

Alternatively, download the repository as a ZIP file from GitHub and extract it.

### Step 2 — Build the Executable

Locate `build-exe.bat` in the project folder.

**Option A — Double-click**

1. Open the ULTRON project folder.
2. Find `build-exe.bat`.
3. Double-click it.
4. Wait for the build process to complete.
5. Read the terminal output for the result and any errors.

**Option B — PowerShell**

Open PowerShell in the project directory and execute:

```powershell
.\build-exe.bat
```

Keep the terminal open until the build finishes. Install any required dependencies if the script reports that they are missing.

### Step 3 — Locate the Generated Executable

When the build completes, check the output path shown by the script.

Locate the generated `.exe` file. Depending on the packaging configuration, it may be an installer or the application executable itself.

### Step 4 — Install or Launch ULTRON

1. Double-click the generated executable.
2. If it is an installer, follow the on-screen instructions.
3. Complete the installation.
4. Launch ULTRON from the installed location or the shortcut created by the installer.

The exact output directory and installation procedure depend on the current build script.

### Step 5 — Windows SmartScreen Warning

Windows may show a **“Windows protected your PC”** warning when an executable is not recognized.

If you have verified that the executable comes from a trusted source:

1. Click **More info**.
2. Review the displayed application information.
3. Click **Run anyway** if you trust the executable and that option is available.
4. Follow the remaining installation or launch instructions.

**Security notice:** Do not bypass a warning for an unknown or unverified executable. Verify the source and scan the file if you are uncertain.

### Step 6 — Configure Your API Keys

After installation:

1. Open ULTRON.
2. Navigate to **Settings**.
3. Scroll down to the API key configuration section.
4. Choose your cloud AI provider.
5. Enter the corresponding API key.
6. Select the appropriate model if necessary.
7. Save the configuration and test the assistant.

For Ollama offline mode, select the local provider and configure the local endpoint and downloaded model instead. Local inference does not ordinarily require a cloud API key.

---

## ⚙️ Configuration Reference

| Setting | Example |
|---|---|
| AI mode | Online or Local |
| Local provider | Ollama |
| Local endpoint | `http://localhost:11434` |
| Example local model | `llama3.2:3b` |
| Cloud API key | Obtained from the chosen provider |
| Offline model download | Complete before disconnecting |

The exact settings names may differ depending on the current application version.

---

## 🖥️ System Requirements

- Windows 10 or Windows 11.
- Sufficient disk space for the application and its dependencies.
- Required build tools and runtimes for building from source.
- Internet access for downloading the source, dependencies, cloud AI access, and Ollama models.
- For offline AI, sufficient memory and processing capability for the chosen model.

Local models can require substantial disk space and memory. Select a model appropriate for your hardware.

---

## 📂 Project Structure

The repository may contain components similar to these:

```text
ULTRON/
├── build-exe.bat
├── app.js
├── index.html
├── apps.json
├── .env.example
└── Other source files, assets, and installer resources
```

This is an illustrative overview. Refer to the actual repository for the complete and current project structure.

---

## 🔐 Security, Privacy & API Keys

- Never publish private API keys in your source code or GitHub repository.
- Keep real credentials out of `.env.example`.
- Use local environment configuration or the application's supported secure settings mechanism.
- Revoke and replace any API key that becomes exposed.
- Review permissions before enabling file access or system-control functionality.
- Download software and models only from trusted sources.

### Privacy in Ollama Mode

When ULTRON sends prompts to a local Ollama model, those prompts can be processed on your computer rather than sent to a cloud AI provider.

However, local inference does not guarantee that the entire application is offline. Other integrations may still make network requests. A fully offline setup must avoid cloud-dependent features and any services that require internet access.

---

## 🧰 Troubleshooting

### `build-exe.bat` fails

- Verify that the script exists in the project folder.
- Run it from PowerShell to inspect the output.
- Check the error message for missing dependencies or build tools.
- Confirm that the project has been extracted completely.

### ULTRON does not start

- Verify that the executable was built successfully.
- Check the output directory for required resources.
- Review any error messages.
- Confirm that required runtimes and dependencies are installed.

### Cloud AI does not respond

- Verify the API key in Settings.
- Check internet connectivity.
- Confirm the selected provider and model.
- Review provider access, usage limits, and billing requirements.

### Ollama is not responding

Check the installed models:

```powershell
ollama list
```

If the expected model is missing, download it while online:

```powershell
ollama pull llama3.2:3b
```

Make sure Ollama is running and the configured endpoint is correct:

`http://localhost:11434`

### Offline mode does not work

- Confirm the model was downloaded before disconnecting from the internet.
- Verify that ULTRON supports Ollama.
- Check that the selected model name matches an installed model.
- Confirm that Ollama is running locally.
- Disable or avoid features that require cloud services.

### Settings are not saved

- Use the application's Save or Apply option if available.
- Restart ULTRON and verify the configuration.
- Check that the application can write to its configuration location.
- Never solve configuration issues by publishing real credentials.

---

## 🗺️ Roadmap

Potential future improvements include:

- [ ] Complete cloud AI provider integration.
- [ ] Ollama integration for local AI inference.
- [ ] Easy switching between online and local modes.
- [ ] Clear online/offline connection status.
- [ ] Improved API key and provider settings.
- [ ] Enhanced AI conversations.
- [ ] Expanded desktop and file-management tools.
- [ ] More productivity integrations.
- [ ] Refined holographic HUD animations.
- [ ] Improved executable packaging and installation.
- [ ] Better diagnostics and error messages.

These items represent potential development goals and are not a claim that every feature is already implemented.

---

## 👨‍💻 Author

**Devendra — Independent Developer**

GitHub: [@its-me-Devendra-2015](https://github.com/its-me-Devendra-2015)

**Repository:** [ULTRON — Source Code](https://github.com/its-me-Devendra-2015/Ultron--devendra_builds)

---

## 📜 License

Check the repository for a `LICENSE` file before redistributing or using this project commercially. If no license is included, do not assume that unrestricted reuse or redistribution is permitted.

---

<p align="center">
  <strong>🔴 ULTRON</strong><br>
  <em>Your Personal AI Command Center</em><br><br>
  Cloud Intelligence. Local AI. One Unified Experience.
</p>
