# Ecosystem Shortlist

All statuses are preliminary research dispositions as of `2026-09-09`. They are not permission to install on the host.

## Native-First Rule

OpenCode native themes, keybinds, attention, commands, formatters, LSP, agents, permissions, custom tools, skills, and MCP configuration should be tested before adding a third-party package. Pi's native extension API, resources, themes, skills, and CLI composition should be tested before adding a package.

## Pi Candidates

| Candidate | Version observed | Capability | Risk / overlap | Disposition |
|---|---:|---|---|---|
| `pi-simplify` | `0.2.3` | Git diff-based follow-up cleanup workflow | No direct writes in inspected code, but follow-up agent can edit | `TRY` in disposable branch |
| `@gotgenes/pi-permission-system` | `31.1.3` | Fail-closed tool/path/Bash/skill gate | In-process policy, not OS sandbox | `PILOT` |
| `@narumitw/pi-plan-mode` | `0.57.1` | Read-only plan workflow with tool policy | Plan export path containment is unsafe; constrain or disable export | `PILOT` |
| `@plannotator/pi-extension` | `0.27.12` | Browser plan/code review | Local server, subprocesses, uploads/integrations; headless fallback can auto-approve | `PILOT` with UI only |
| `pi-mcp-adapter` | `2.32.1` | MCP discovery, OAuth, keyring, allowlists | `npm exec`, arbitrary configured commands/URLs, secret providers | `PILOT` with allowlists |
| `@narumitw/pi-lsp` | Recheck | LSP/code intelligence | Version/runtime compatibility and process access | `PILOT` after static audit |
| `pi-lens` | `4.1.4` | LSP/code quality | Build/prepare downloads grammars, writes cache/logs, large package | `DEFER` |
| `pi-subagents` | `0.66.0` | Foreground/background child agents | Installer clones mutable Git and runs `git pull` globally | `DEFER` |
| `pi-powerline-footer` | Recheck | Rich statusline, queues, Git polling | Broad features, file writes, optional model calls | `DEFER` |

Evidence: [Pi security](https://pi.dev/docs/latest/security), [Pi containerization](https://pi.dev/docs/latest/containerization), [permission boundary](https://unpkg.com/@gotgenes/pi-permission-system@31.1.3/src/handlers/tool-call-boundary.ts), [Plan Mode](https://unpkg.com/@narumitw/pi-plan-mode@0.57.1/dist/index.ts), [Pi MCP adapter](https://unpkg.com/pi-mcp-adapter@2.32.1/README.md).

## OpenCode Candidates

| Candidate | Version observed | Capability | Risk / overlap | Disposition |
|---|---:|---|---|---|
| `@opencode-ai/plugin` | `1.18.29` registry; local `1.14.25`/`1.15.10` | Official plugin API baseline | Host-level plugin privilege | `TRY` as API reference, not feature install |
| `@plannotator/opencode` | `0.27.12` | Visual plan/diff review | Postinstall writes global commands/skills; local server/network paths | `PILOT` in disposable config |
| `@tarquinen/opencode-dcp` | `3.1.15` | Dynamic context pruning | Native compaction overlap; auto-update/npm query/global config mutation | `DEFER` until A/B test |
| `opencode-vibeguard` | `0.1.0` | Provider-side secret/PII redaction | Security-critical correctness; local tool args/output remain plaintext | `PILOT` after source audit |
| `opencode-pty` | `0.3.6` | Background PTY and WebSocket UI | Confirmed direct web process-spawn path, weak auth, host override, path-boundary bug | `AVOID` pending fix/audit |
| `@upstash/context7-mcp` | `4.0.6` | Context7 MCP transport | Sends queries/content to external service; native remote MCP overlaps | `TRY` via controlled remote/native config |
| `octto` | `0.4.1` | Browser brainstorming and branching | Local server, prompt injection/configured fragments, multiple sessions | `PILOT` |
| `micode` | `0.10.0` | Brainstorm/research/plan/implement orchestration | Large overlap with native agents/commands/skills and PTY/worktrees | `DEFER` |
| `@daytona/opencode` | `0.192.1` | Cloud sandbox sessions | Uploads/syncs repo, API key, branches/remotes, cost | `DEFER` |
| `opencode-supermemory` | `2.0.13` | External persistent memory | External API/key, automatic capture and auto-approved search | `DEFER` |
| `oh-my-opencode` | `4.19.4` npm | Broad orchestration and hooks | Telemetry, MCPs, many hooks, PTY/tmux, postinstall cache mutation | `AVOID` pending audit |
| `oh-my-openagent` | `4.19.4` npm observation | Identity/alias requires separate verification | Do not merge its risk profile with `oh-my-opencode` until source/tarball mapping is proven | `AVOID` pending identity |
| `opencode-background-agents` | `0.1.1` | Async read-only delegation | npm/source identity mismatch; provenance unresolved | `AVOID` pending provenance |

Evidence: [OpenCode plugins](https://opencode.ai/docs/plugins/), [permissions](https://opencode.ai/docs/permissions/), [ecosystem](https://opencode.ai/docs/ecosystem/), [PTY authorization finding](https://unpkg.com/opencode-pty@0.3.6/dist/src/plugin/pty/permissions.js), [DCP update behavior](https://unpkg.com/@tarquinen/opencode-dcp@3.1.15/lib/update.ts).

## Confirmed Risk Signals

- Pi packages/extensions run in-process and may have full host access; Pi itself has no built-in sandbox.
- `pi-mcp-adapter` can execute `npm exec` on cache miss and launch configured MCP processes.
- `pi-subagents` clones mutable remote Git into the global Pi extension directory.
- `@plannotator/opencode` writes commands and skills into the global OpenCode config during postinstall.
- DCP auto-update queries npm, may mutate its cache wrapper, and creates global config.
- `opencode-pty` web routes can spawn/access/terminate processes without the model permission check; host override can expose the server beyond loopback.
- VibeGuard redacts provider requests but does not remove plaintext from local tool arguments/output.
