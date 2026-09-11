# Release Timeline

## OpenCode

| Release | Date | Milestone |
|---|---|---|
| `v0.0.1` | `2025-04-22` | Go/Bubble Tea CLI, early-development phase |
| `v0.1.0` | `2025-06-12` | Bun/TypeScript package phase; Go module absent |
| `v0.10.0` | `2025-09-18` | Custom tools, plugin tool updates, GLM coding-plan support, compaction fixes |
| `v1.0.0` | `2025-10-31` | Go/Bubble Tea to OpenTUI rewrite using Zig/SolidJS; keybind/theme breaking changes |
| `v1.14.42` | 2026 | Scout agent, workspace sync, compressed HTTP responses |
| `v1.14.49` | 2026 | v2 model/provider API, DigitalOcean OAuth, global config, built-in customize workflow |
| `v1.15.12` | 2026 | ACP-next, OpenAI WebSockets, workspace management |
| `v1.16.0` | 2026 | Managed workspace cloning, skills/agents, session replay, Bedrock support |
| `v1.18.29` | `2026-09-04` | Codex OAuth filtering fix for integer GPT versions such as `gpt-6` |

Source: [OpenCode releases](https://github.com/anomalyco/opencode/releases), [official changelog](https://opencode.ai/changelog), [release Atom feed](https://github.com/anomalyco/opencode/releases.atom), [npm package](https://registry.npmjs.org/opencode-ai/1.18.29).

## Pi Summary

The complete Pi launch and package crosswalk is in [`pi-release-archeology.md`](./pi-release-archeology.md). The important chronology rule is to keep repository tags, package publications, coding-agent releases, and maintainer labels as separate streams.

## Cross-Engine Interpretation

- OpenCode has a visible product transition from a Go TUI to a TypeScript/Bun/OpenTUI client/server system.
- Pi's version line remains pre-1.0 while its coding-agent package and extension surface mature rapidly.
- OpenCode adds integrated product capabilities earlier: agents, permissions, MCP, server/client, workspace, and TUI contracts.
- Pi adds capability through a smaller core, package lineage, extension API, session durability, and user-composed workflow.
- Do not compare Pi early package versions with OpenCode current stable for current capability claims. Use historical rows only for architecture/release trajectory.
