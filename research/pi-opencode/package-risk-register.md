# Package Risk Register

| Package | Category | Confirmed risk | Control | Disposition |
|---|---|---|---|---|
| `@gotgenes/pi-permission-system@31.1.3` | Pi extension | In-process policy, not sandbox | Run fail-closed gate tests in container | `PILOT` |
| `@narumitw/pi-plan-mode@0.57.1` | Pi extension | Plan export path is not containment-safe | Disable export or enforce external path boundary | `PILOT` |
| `@plannotator/pi-extension@0.27.12` | Pi extension | Local server, VCS subprocesses, optional network, auto-approve fallback | Interactive UI only; disposable worktree | `PILOT` |
| `pi-mcp-adapter@2.32.1` | Pi package, MCP adapter | `npm exec`, arbitrary configured commands/URLs, secret providers | Explicit server/tool allowlist and approval | `PILOT` |
| `pi-lens@4.1.4` | Pi package | Prepare downloads grammars and writes cache/logs | Static install in disposable HOME | `DEFER` |
| `pi-subagents@0.66.0` | Pi extension | Clones mutable Git and runs `git pull` globally | Pin source commit; no host install | `DEFER` |
| `@plannotator/opencode@0.27.12` | OpenCode plugin | Postinstall writes global commands/skills | Disposable config; inspect postinstall | `PILOT` |
| `@tarquinen/opencode-dcp@3.1.15` | OpenCode plugin | npm update check, cache mutation, global config, native compaction overlap | Disable auto-update; A/B against native compaction | `DEFER` |
| `opencode-pty@0.3.6` | OpenCode plugin | Web process routes bypass model permission, weak auth, path boundary issue | Do not run until fixed and externally sandboxed | `AVOID` |
| `opencode-vibeguard@0.1.0` | OpenCode plugin | Redaction correctness; local plaintext remains | Synthetic secrets and provider/local log checks | `PILOT` |
| `@upstash/context7-mcp@4.0.6` | MCP server | External query/content path and package install lifecycle | Native/remote controlled endpoint; pin package | `TRY` |
| `opencode-supermemory@2.0.13` | OpenCode plugin | External API/key and automatic conversation capture | Explicit consent and disposable profile | `DEFER` |
| `oh-my-opencode@4.19.4` | OpenCode plugin/distribution | Telemetry, many hooks/MCPs, PTY/tmux, postinstall mutation | Full source audit and isolated profile | `AVOID` pending audit |
| `oh-my-openagent@4.19.4` | Separate package identity/alias to verify | Do not assume it is identical to `oh-my-opencode` | Resolve repository, tarball, and package identity first | `AVOID` pending identity |

## Hard Rejection Conditions

- Unknown package-to-repository identity or unverifiable tarball integrity.
- Unexpected lifecycle script, global write, child process, or network egress.
- Credential or synthetic-secret leakage.
- Permission bypass or host process exposure.
- No OS-level sandbox for a package with broad process/filesystem/network capability.
