# Local Baseline

## Repository State Observed

At collection time the worktree contained changes in `nvim/init.lua`, `nvim/lazy-lock.json`, `nvim/todo.md`, `opencode/opencode.json`, an untracked `TODO.md`, and an untracked `nvim/lua/plugins/codecompanion.lua`. These files were not reverted or modified during research.

## OpenCode Learn Profile

Source: `opencode-learn/package.json`, `opencode-learn/package-lock.json`, `opencode-learn/opencode.json`.

- `@opencode-ai/plugin` is pinned to `1.15.10` as a dependency/API package.
- The dependency is not itself a loaded plugin; `opencode-learn/opencode.json` has no `plugin` declaration.
- Default agent: `learn`.
- `learn`: edit denied; Bash denied except `dotnet build`, `dotnet run`, and `dotnet test`; task delegation allows only `brutally-honest`.
- `brutally-honest`: hidden subagent with edit, write, and Bash denied.
- The learn prompt appears to describe state-file writes despite explicit edit denial and no explicit write allowance; verify effective runtime behavior before relying on it.

## Global OpenCode Profile

Source: `opencode/opencode.json`.

- Default agent: `explore`.
- Global registry plugins currently declared: `@tarquinen/opencode-dcp@3.1.15` and `vim@0.1.0`.
- Local plugin modules observed: `caveman.ts` and `rtk.ts` under the deployed OpenCode config.
- Enabled MCPs: local `bm25` and local Context7 via unpinned `npx -y @upstash/context7-mcp`.
- Disabled MCPs: Microsoft Learn and Chrome DevTools; the latter still uses `@latest` in its command.
- Global permission defaults ask for edit/write/Bash, while the `explore`, `research`, and `brainstorm` agents narrow permissions.
- The global API dependency is separately pinned to `@opencode-ai/plugin@1.14.25` in the ignored package manifest.

## Pi Profile

Source: `/home/raisal/.pi/agent/settings.json`, `/home/raisal/.pi/agent/npm/package-lock.json`, and `/home/raisal/.pi/agent/trust.json`.

- Current selected model/provider observed: `gpt-5.6-luna` / `openai-codex`.
- Local Pi package globs auto-load extensions from the Pi agent directory.
- The lockfile resolves packages including `pi-goal`, dynamic workflows, `pi-btw`, and `pi-napkin`.
- Trusted paths do not include `/home/raisal/dotfiles` in the observed trust file.
- Pi package declarations and state are outside the dotfiles repository and require a separate redacted backup before trials.

## Safe Trial Boundary

1. Use a separate unprivileged container, VM, or OS user with a disposable `HOME` and XDG directories.
2. Do not mount the host `.pi`, `.config/opencode`, SSH agent, keyring, or auth databases.
3. Start with no MCP, no local plugins, and deny edit/write/Bash.
4. Use a throwaway fixture repository and one exact package version per trial.
5. Promote only a reviewed config/lockfile patch after rollback testing.
