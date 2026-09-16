---
name: clash-ai-whitelist
description: Configure Clash Verge Rev on Linux as a whitelist proxy for ChatGPT/Codex, GitHub, Hugging Face, Claude, Gemini, Grok and common AI/algorithm-engineering services while keeping all other traffic DIRECT.
---

# Clash AI Whitelist

Use this skill when the user wants Clash Verge Rev to proxy only selected AI/developer services and keep everything else direct.

## Safety rules

- Never print or upload `profiles.yaml`, subscription URLs, node passwords, UUIDs, or private proxy files.
- Back up `verge.yaml`, `config.yaml`, and `profiles/Script.js` before changing them.
- Prefer the global `profiles/Script.js` extension instead of subscription-local Rules files.
- Keep `MATCH,DIRECT` as the final managed rule.
- Do not proxy broad suffixes such as all of `google.com`, `amazonaws.com`, or `microsoft.com` unless the user explicitly requests that.
- If a custom global Script.js already exists, preserve it via the installer backup and tell the user where the backup is.

## Standard workflow

1. Inspect current state:

```bash
./scripts/status.sh
```

2. Install/update the whitelist:

```bash
./scripts/install.sh --proxy-group "🔰 选择节点"
```

If the proxy group has a different name, pass the exact group name. The installed JavaScript can also auto-detect a `select` proxy group.

3. Verify the generated runtime config:

```bash
./scripts/status.sh
```

Expected:
- `enable_tun_mode: true`
- `enable_system_proxy: true` unless the user opted out
- `mode: rule`
- runtime rules include `chatgpt.com`, `github.com`, `huggingface.co`, `claude.ai`, `grok.com`
- runtime rules end in `MATCH,DIRECT`

4. If Clash Verge Rev does not regenerate the runtime config, restart/reopen the app and reactivate the current profile, then rerun status.

5. Roll back when requested:

```bash
./scripts/uninstall.sh
```

## Notes

The installer targets these common Linux data locations automatically:
- `~/.local/share/io.github.clash-verge-rev.clash-verge-rev`
- `~/.config/io.github.clash-verge-rev.clash-verge-rev`
- `~/.config/clash-verge-rev`

Override with:

```bash
CLASH_VERGE_HOME=/path/to/app-data ./scripts/install.sh
```

The domain list is maintained in `assets/Script.js`.
