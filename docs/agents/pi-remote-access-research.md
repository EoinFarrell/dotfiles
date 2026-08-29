# Pi Coding Agent remote-access research

Goal: find ways to reach a long-lived Pi session running in a homelab container from a phone, from anywhere.

## Quick comparison

| Option | What it is | Transport / relay | Self-hostable | Phone UX | Ad-hoc commands | Long-lived session | Files | Auth story |
|---|---|---|---|---|---|---|---|---|
| **PI WEB** | Official web UI for Pi | HTTP + WebSocket, direct or reverse proxy | Yes (your own server) | Responsive PWA | Full chat + terminal | Yes (session daemon) | Upload/download UI, file explorer | Trust boundary only; put behind VPN/auth proxy |
| **pi-telegram** | Telegram DM bridge Pi extension | Telegram Bot API (cloud) | N/A (uses Telegram) | Telegram mobile app | Text + images/files | Tied to one interactive Pi session | In/out images & files | First-DM pairs allowed user ID |
| **pi-discord (npm)** | Discord bot / Pi extension + daemon | Discord Gateway (cloud) | Runs on your host | Discord mobile app | Slash + mentions + DMs | Per-channel persistent sessions | In/out attachments, `discord_upload` tool | Guild allowlist, DM allowlist, admin IDs |
| **piscord** | Standalone Discord gateway | Discord Gateway (cloud) | Runs on your host | Discord mobile app | Slash commands + DMs | Per-channel sessions + SQLite queue | Attachment relay, `piscord send` | Channel policy + allowlists |
| **pi-remote** | WebSocket-first server runtime | WebSocket/HTTP, direct or TLS proxy | Yes | Custom clients / Discord bot | Any Pi RPC command | One session per WebSocket conn; session mgmt | Raw file paths via bot code | Optional API key |
| **Pi RPC / JSON event stream** | Built-in headless Pi protocols | stdin/stdout JSONL | Yes (wrap yourself) | Build your own client | All commands | Yes if you manage process | Base64 images in protocol | Whatever you add |

Sources: [PI WEB install](https://pi-web.dev/install), [PI WEB FAQ](https://pi-web.dev/faq), [pi-telegram README](https://github.com/badlogic/pi-telegram), [pi-discord README](https://github.com/nicobailon/pi-discord), [piscord README](https://github.com/Crokily/pi-discord-gateway), [pi-remote README](https://github.com/k3-2o/pi-remote), [Pi RPC docs](https://pi.dev/docs/latest/rpc), [Pi JSON event docs](https://pi.dev/docs/latest/json).

---

## 1. PI WEB (pi-web.dev)

### What it is
PI WEB is a web UI for Pi Coding Agent that keeps sessions alive in real workspaces on a machine or server, accessible from any browser. It runs as a session daemon plus a web/API server. [PI WEB homepage](https://pi-web.dev/)

### How it works
- Two per-user services: `pi-web-sessiond` (long-lived session daemon) and `pi-web-server` (web/API server). [PI WEB install](https://pi-web.dev/install)
- Default bind: `127.0.0.1:8504`. [PI WEB install](https://pi-web.dev/install)
- Sessions survive browser disconnects and web/API restarts because they live in the session daemon. [PI WEB FAQ](https://pi-web.dev/faq)
- Supports machine federation: one browser-facing gateway can proxy multiple Pi WEB runtimes. [PI WEB machines](https://pi-web.dev/machines)

### Protocol / transport
- HTTP and WebSocket between browser and `pi-web-server`; the server proxies to the session daemon over a Unix socket or TCP (configurable via `PI_WEB_SESSIOND_SOCKET` / `PI_WEB_SESSIOND_URL`). [PI WEB config](https://pi-web.dev/config)
- Nginx reverse-proxy example shows WebSocket upgrade forwarding, authenticated prefix deployments, and path stripping. [PI WEB install](https://pi-web.dev/install)

### Hosted relay / self-hosting
- No hosted relay; you run it yourself. Install via `npm install -g @jmfederico/pi-web`. [PI WEB install](https://pi-web.dev/install)
- Can run in a container manually with `pi-web-sessiond` + `PI_WEB_PORT=8504 pi-web-server`. [PI WEB install](https://pi-web.dev/install)
- Federation lets one self-hosted gateway reach other self-hosted runtimes. [PI WEB machines](https://pi-web.dev/machines)

### Security implications
- PI WEB explicitly assumes trusted users and trusted server paths; it is not a sandbox or multi-tenant platform. [PI WEB README security model](https://github.com/jmfederico/pi-web#security-model)
- Do not expose directly to the public internet. Recommended: SSH tunnel, VPN (Tailscale/WireGuard/NetBird), private LAN, or authenticated reverse proxy. [PI WEB FAQ](https://pi-web.dev/faq)
- Path access outside the workspace is denied by default and must be allow-listed in `pathAccess.allowedPaths`. [PI WEB config](https://pi-web.dev/config)

### Phone-friendliness
- Responsive/mobile UI is a first-class feature; screenshots show mobile chat controls. [PI WEB homepage](https://pi-web.dev/)
- Works as a PWA with offline-aware assets; prefix deployments keep PWA scope correct. [PI WEB install](https://pi-web.dev/install)

### Support matrix
- (a) Ad-hoc commands: yes — full chat composer with `@` file completions and `/` commands.
- (b) Long-lived session: yes — session daemon owns the runtime.
- (c) Files/attachments: yes — drag/drop upload, file explorer, preview panel.
- (d) Auth: trust-boundary only; add VPN, proxy auth, or bearer-token machine federation.

---

## 2. pi-telegram

### What it is
`badlogic/pi-telegram` is a Telegram DM bridge extension for Pi. It forwards Telegram DMs into the current Pi session and sends replies back. [pi-telegram README](https://github.com/badlogic/pi-telegram)

### How it works
- Installed as a Pi package (`pi install git:github.com/badlogic/pi-telegram`). [pi-telegram README](https://github.com/badlogic/pi-telegram)
- Runs **inside the active Pi session** (`/telegram-connect`); it is session-local, not a separate long-lived daemon. [pi-telegram README](https://github.com/badlogic/pi-telegram)
- Polls the Telegram Bot API (`https://api.telegram.org/bot<token>/getUpdates`) with long-polling (30 s timeout, offset tracking). [pi-telegram index.ts](https://raw.githubusercontent.com/badlogic/pi-telegram/main/index.ts)
- Messages from Telegram are prefixed with `[telegram]` and injected via `pi.sendUserMessage()`. [pi-telegram index.ts](https://raw.githubusercontent.com/badlogic/pi-telegram/main/index.ts)

### Commands / controls
- `/telegram-setup` — prompt for bot token, store in `~/.pi/agent/telegram.json`.
- `/telegram-connect` / `/telegram-disconnect` — start/stop polling in the current session.
- `/telegram-status` — show bot, allowed user, polling state, queued turns.
- In Telegram: text, `stop`/`/stop`, `/status`, `/compact`, `/help`, `/start`. [pi-telegram README](https://github.com/badlogic/pi-telegram)

### Separate runtime or same session?
Same session. If the interactive Pi session exits, the Telegram bridge stops. It does not provide a detached daemon. [pi-telegram index.ts session_shutdown handler](https://raw.githubusercontent.com/badlogic/pi-telegram/main/index.ts)

### Install / config
1. Create bot with @BotFather, copy token.
2. `pi install git:github.com/badlogic/pi-telegram`
3. In Pi: `/telegram-setup`, paste token.
4. `/telegram-connect` in the session that should own the bot.
5. Send `/start` from Telegram; first DM user becomes the allowed user. [pi-telegram README](https://github.com/badlogic/pi-telegram)

### Security / limitations
- Only one Pi session should be connected to the bot at a time. [pi-telegram README](https://github.com/badlogic/pi-telegram)
- First Telegram user to send `/start` is hard-coded as the allowed user; others are rejected. [pi-telegram index.ts](https://raw.githubusercontent.com/badlogic/pi-telegram/main/index.ts)
- Uses Telegram cloud API; no end-to-end encryption guarantee (standard Telegram-bot model).
- Attachment handling: downloads to `~/.pi/agent/tmp/telegram`, passes local paths and inline images to Pi; outbound files use a `telegram_attach` tool. [pi-telegram README](https://github.com/badlogic/pi-telegram)

### Support matrix
- (a) Ad-hoc commands: yes.
- (b) Long-lived session: **no** — bridge dies with the interactive session. Not suitable for a container that must keep running unattended.
- (c) Files/attachments: yes (images, albums, files, outbound via `telegram_attach`).
- (d) Auth: first-user pairing only; no ACLs.

---

## 3. Discord integrations

Several community projects bridge Discord to Pi. None is official.

### 3.1 `pi-discord` (npm `pi-discord`, GitHub `nicobailon/pi-discord`)
- **Maturity:** 36 stars, 8 commits, published to npm (v0.2.5). [npm pi-discord](https://www.npmjs.com/package/pi-discord), [GitHub](https://github.com/nicobailon/pi-discord)
- **Architecture:** Pi extension + **detached daemon** (`pi-discord-daemon`) that stays online independently of Pi. [pi-discord README](https://github.com/nicobailon/pi-discord)
- **Sessions:** per-route (guild/channel/thread) persistent Pi sessions via the Pi SDK (`createAgentSession()`). [pi-discord README](https://github.com/nicobailon/pi-discord)
- **Ingress:** slash commands (`/pi ask`, `/pi status`, `/pi stop`, `/pi reset`), @mentions, DMs.
- **Files:** inbound attachments downloaded to route workspace; outbound via `discord_upload` tool; `discord_react` tool for reactions. [pi-discord README](https://github.com/nicobailon/pi-discord)
- **Auth:** optional `allowedGuildIds`, `dmAllowlistUserIds`, `adminUserIds`; project extensions off by default. [pi-discord README](https://github.com/nicobailon/pi-discord)
- **Config:** `~/.pi/agent/pi-discord/config.json`. [pi-discord README](https://github.com/nicobailon/pi-discord)

### 3.2 `piscord` (npm `piscord`, GitHub `Crokily/pi-discord-gateway`)
- **Maturity:** 44 stars, 51 commits, actively versioned (latest 1.7.0 as of docs). [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Architecture:** standalone Node daemon that **shells out to the `pi` binary** (`pi --session-dir <dir> --continue -p <msg>`), not an in-process extension. [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Sessions:** per-channel sessions stored under `~/.local/share/piscord-gateway/sessions/`. [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Queue:** SQLite-backed queue with crash recovery and lease expiration. [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Ingress:** slash commands (`/pi status`, `/pi model`, `/pi thinking`, `/pi new`, `/pi stop`), @mentions, DMs; channel policy `open` / `open-trigger` / `allowlist`. [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Files:** attachment relay to local paths; `piscord send --file` for outbound files. [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Auth:** channel allowlist, DM auto-registration, excluded channels. [piscord README](https://github.com/Crokily/pi-discord-gateway)
- **Daemon:** systemd (Linux) / launchd (macOS) support. [piscord README](https://github.com/Crokily/pi-discord-gateway)

### 3.3 `pi-discord-threads` (GitHub `joelhooks/pi-discord-threads`)
- **Maturity:** 8 stars, 97 commits, personal-project style. [pi-discord-threads README](https://github.com/joelhooks/pi-discord-threads)
- **Architecture:** local Discord bot that maps Discord threads to real Pi session files; also supports Claude Code.
- **Sessions:** persistent per-thread Pi sessions; can resume, fork, list sessions.
- **Ingress:** slash commands and `!pi` prefix; context channels; workspace aliases.
- **Files:** attachments downloaded to local data dir, small images inline.
- **Auth:** trusted-user allowlist, challenge code for first contact; group chats silent until enabled. [pi-discord-threads README](https://github.com/joelhooks/pi-discord-threads)
- **Run control:** optional Redis for leases/heartbeats across bridge processes.

### 3.4 Other Discord bridges
- `hoshi-discord-integration` (0 stars): Pi extension for Discord DMs only; allowlisted user IDs; registers tools like `discord_send_message`, `discord_download_attachment`. [GitHub](https://github.com/lmbt/hoshi-discord-integration)
- `pi-discord-remote` / `@mporenta/pi-discord-remote` (npm): Pi extension for bidirectional Discord remote control of a local Pi session. [npm pi-discord-remote](https://www.npmjs.com/package/pi-discord-remote), [npm @mporenta/pi-discord-remote](https://www.npmjs.com/package/@mporenta/pi-discord-remote)
- `@lalalic/channel`: transparent channel bridge for Pi supporting Discord and WeChat. [npm](https://www.npmjs.com/package/@lalalic/channel)

### Discord option summary
| Bridge | Best for | Maturity signal | Daemon? | Per-chat sessions | File support |
|---|---|---|---|---|---|
| `pi-discord` | Server/team use, persistent sessions | Medium (npm, tests, config docs) | Yes | Yes | Yes |
| `piscord` | Lightweight self-hosted gateway | Highest stars, versioned, docs | Yes | Yes | Yes |
| `pi-discord-threads` | Personal thread-per-task workflow | Low stars, high commit count, bespoke | Yes (LaunchAgent) | Yes | Yes |
| `hoshi-discord-integration` | Simple DM-only extension | Very early | No (extension) | No | Yes |

---

## 4. Pi built-in RPC / SSE / API and SSH execution extension

### 4.1 RPC mode
- `pi --mode rpc` runs Pi headlessly with a JSONL protocol over stdin/stdout. [Pi RPC docs](https://pi.dev/docs/latest/rpc)
- Supports all major commands: `prompt`, `steer`, `follow_up`, `abort`, `set_model`, `bash`, `compact`, `new_session`, `switch_session`, `fork`, `get_state`, `get_messages`, etc. [Pi RPC docs](https://pi.dev/docs/latest/rpc)
- Streams events: `agent_start`, `agent_end`, `message_start`, `message_update`, `tool_execution_*`, `queue_update`, etc. [Pi RPC docs](https://pi.dev/docs/latest/rpc)
- Extension UI (dialogs) is supported via a sub-protocol on stdin/stdout. [Pi RPC docs](https://pi.dev/docs/latest/rpc)
- SDK alternative: use `AgentSession` directly in Node.js instead of spawning a subprocess. [Pi RPC docs](https://pi.dev/docs/latest/rpc)

### 4.2 JSON event stream mode
- `pi --mode json "prompt"` prints all session events as JSON lines to stdout. [Pi JSON docs](https://pi.dev/docs/latest/json)
- Good for integrating into other tools or custom UIs; no bidirectional control beyond stdin. [Pi JSON docs](https://pi.dev/docs/latest/json)

### 4.3 SDK
- `@earendil-works/pi-coding-agent` exposes `createAgentSession`, `AgentSessionRuntime`, `SessionManager`, etc. [Pi SDK docs](https://pi.dev/docs/latest/sdk)
- You can embed Pi in a Node app, subscribe to events, and call `session.prompt()`, `session.steer()`, etc. [Pi SDK docs](https://pi.dev/docs/latest/sdk)

### 4.4 SSH execution extension (`examples/extensions/ssh.ts`)
- A Pi extension example that makes `read`/`write`/`edit`/`bash` tools execute over SSH instead of locally. [ssh.ts source](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/ssh.ts)
- It wraps local tool factories with remote `ReadOperations`/`WriteOperations`/`BashOperations` that run `ssh user@host <cmd>`. [ssh.ts source](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/ssh.ts)
- This is about **where tools run**, not about remote control of a Pi session. It is useful if you want a local Pi TUI to operate on a remote container filesystem.

### What these primitives provide for a phone bridge
| Primitive | Useful for | Gap to fill |
|---|---|---|
| RPC mode | Bidirectional control, steering, abort, model switching | Needs a network server wrapper and a phone client |
| JSON event stream | One-way monitoring / custom dashboards | No phone-native client; no steering |
| SDK | Build a custom long-lived bridge in Node | Must implement transport/auth/phone UI |
| SSH extension | Run tools on the homelab host from a local Pi | Does not remote-control the session itself |

---

## 5. Recommendations for the homelab/phone use case

### If you want the simplest, most official path
**Use PI WEB** inside the container (manual run or a small systemd/user service), put it behind Tailscale/WireGuard/NetBird or an authenticated reverse proxy, and open it from the phone browser. It gives full session persistence, file handling, and a mobile UI. The main caveat is security: treat it as a trusted-internal app, never expose raw `0.0.0.0:8504` to the internet. [PI WEB install](https://pi-web.dev/install), [PI WEB FAQ](https://pi-web.dev/faq)

### If you want chat-native mobile access without a VPN
**Use `piscord` or `pi-discord`** as a daemon alongside Pi in the container. Discord becomes the client; no open inbound port is needed (outbound Discord Gateway only). This is a strong fit for ad-hoc commands from a phone, but the interaction model is chat/thread-based rather than a full IDE UI. Prefer `piscord` for a standalone, versioned gateway; prefer `pi-discord` if you want tighter Pi-extension integration.

### If you want Telegram instead of Discord
**`pi-telegram`** works well for quick chat, but because it lives inside the interactive Pi session it is **not a good fit** for an unattended long-lived container session. For that scenario, prefer a standalone bridge (piscord/pi-discord style) or PI WEB.

### If you want to build a custom bridge
Use **Pi RPC mode** or the **SDK** as the foundation. For network exposure, wrap RPC with **pi-remote** (WebSocket server) or a small HTTP/WebSocket proxy of your own. You will need to add:
- Transport (WebSocket or HTTP) with TLS and an auth layer.
- A phone client (web app, Telegram bot, Discord bot, etc.).
- Session lifecycle management (pi-remote already provides this).
- File handling mapped to your chosen client.

### What not to use for the stated goal
- `pi-telegram` alone, because the bridge dies with the interactive session.
- The SSH extension alone, because it does not expose the session to a phone.
- Raw RPC over the public internet without TLS + auth.

---

## Sources

- PI WEB homepage: <https://pi-web.dev/>
- PI WEB install / remote access: <https://pi-web.dev/install>
- PI WEB config reference: <https://pi-web.dev/config>
- PI WEB FAQ: <https://pi-web.dev/faq>
- PI WEB machines / fleet: <https://pi-web.dev/machines>
- PI WEB GitHub: <https://github.com/jmfederico/pi-web>
- pi-telegram GitHub: <https://github.com/badlogic/pi-telegram>
- pi-telegram source: <https://raw.githubusercontent.com/badlogic/pi-telegram/main/index.ts>
- Pi docs — Extensions: <https://pi.dev/docs/latest/extensions>
- Pi docs — RPC mode: <https://pi.dev/docs/latest/rpc>
- Pi docs — JSON event stream: <https://pi.dev/docs/latest/json>
- Pi docs — SDK: <https://pi.dev/docs/latest/sdk>
- Pi SSH execution example: <https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/ssh.ts>
- pi-discord GitHub: <https://github.com/nicobailon/pi-discord>
- piscord / pi-discord-gateway GitHub: <https://github.com/Crokily/pi-discord-gateway>
- pi-discord-threads GitHub: <https://github.com/joelhooks/pi-discord-threads>
- pi-courier GitHub: <https://github.com/Hi-Barry/pi-courier>
- pi-remote GitHub: <https://github.com/k3-2o/pi-remote>
- pi-remote protocol reference: <https://github.com/k3-2o/pi-remote/blob/main/docs/reference/protocol.md>
- pi-remote Discord bot how-to: <https://github.com/k3-2o/pi-remote/blob/main/docs/how-to/discord-bot.md>
- hoshi-discord-integration GitHub: <https://github.com/lmbt/hoshi-discord-integration>
- npm pi-discord: <https://www.npmjs.com/package/pi-discord>
- npm piscord: <https://www.npmjs.com/package/piscord>
- npm pi-discord-remote: <https://www.npmjs.com/package/pi-discord-remote>
- npm @lalalic/channel: <https://www.npmjs.com/package/@lalalic/channel>
