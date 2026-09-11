# Comparison Matrix

| Dimension | Pi | OpenCode | Evidence |
|---|---|---|---|
| Core boundary | `pi-ai` -> `pi-agent-core` -> `pi-coding-agent` -> `pi-tui` | schema/core/protocol/server/opencode/client/sdk/cli/tui | `architecture.md` |
| Loop ownership | `Agent` and `runAgentLoop`; harness subscribes to events | `SessionPrompt` and `SessionProcessor` in application runtime | `PI-ARCH-001`, `OC-ARCH-001` |
| Persistence | Append-only JSONL tree with branch IDs | Typed session/message/part data, snapshots, server APIs | `PI-ARCH-003`, OpenCode session sources |
| Context | `buildSessionContext` projection and compaction boundary | Prompt loop compaction and session processor state | Pinned source refs in `architecture.md` |
| Tool scheduling | Parallel default with ordered result reconstruction | Registry -> AI SDK -> Effect bridge | `PI-ARCH-001`, `OC-ARCH-002` |
| Tool permissions | Host permissions by default; extension-level controls | `allow`/`ask`/`deny` rule merge and deferred approval | `SEC-001` |
| Subagents | Extension/process composition; no dedicated built-in coding-agent feature | Built-in Build/Plan and General/Explore/Scout subagents | `philosophy-and-governance.md` |
| Extension model | TypeScript code-first lifecycle and resource discovery | Declarative config plus plugins/custom tools/MCP | Context7 and official plugin docs |
| Config model | Project trust and resource loader | Global/project/managed/remote merge | `OC-ARCH-003` |
| Client model | Interactive, print/JSON, RPC, SDK | TUI client, server, CLI, OpenAPI, SDK, web/IDE | Official README/docs |
| Ricing surface | TUI components, themes, extension UI | Themes, keybinds, TUI slots, plugins, client/server events | Official docs |
| Isolation | No built-in sandbox | Permission UX, no OS sandbox | `SEC-001` |

## Interpretation

- Choose Pi when the desired result is a small, inspectable core and custom workflow code.
- Choose OpenCode when integrated agents, permission UX, MCP, server/client, and multi-surface access matter more than minimal core size.
- Treat package richness as a separate trust decision from engine capability.
