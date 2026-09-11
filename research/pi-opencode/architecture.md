# Architecture Comparison

## Pi

### Package boundaries

| Layer | Responsibility | Official source |
|---|---|---|
| `pi-ai` | Provider, model, auth, streaming, and tool-call primitives | [`packages/ai`](https://github.com/earendil-works/pi/tree/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/ai) |
| `pi-agent-core` | Agent state, loop, message conversion, queues, tool lifecycle | [`agent.ts`](https://github.com/earendil-works/pi/blob/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/agent/src/agent.ts), [`agent-loop.ts`](https://github.com/earendil-works/pi/blob/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/agent/src/agent-loop.ts) |
| `pi-coding-agent` | CLI harness, sessions, resources, extensions, compaction, model state | [`agent-session.ts`](https://github.com/earendil-works/pi/blob/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/src/core/agent-session.ts) |
| `pi-tui` | Differential terminal rendering, components, overlays, focus, scrolling | [`TUI README`](https://github.com/earendil-works/pi/blob/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/tui/README.md) |

### Runtime flow

1. `Agent` runs the loop and owns in-memory state.
2. The loop transforms context, converts messages for the provider, streams the response, validates tool calls, and executes tools.
3. Tool execution is parallel by default while preserving assistant source order in final tool-result messages.
4. `AgentSession` subscribes to agent events and adds persistence, extension dispatch, compaction, model/auth state, Bash, and session switching.
5. `SessionManager` persists an append-only JSONL tree; `id` and `parentId` represent branches without rewriting history.
6. `ResourceLoader` discovers context files, skills, prompts, themes, system prompts, and extensions.

### Context and durability

- Compaction changes the provider projection while retaining the historical session entries.
- Automatic compaction reserves approximately `16,384` tokens and keeps approximately `20,000` recent tokens by default.
- Tool calls and tool results are kept together at compaction boundaries.
- `custom` entries persist extension state without entering LLM context; `custom_message` entries enter context.
- The harness/durability documents contain partly normative, unfinished design work. Do not treat every durability document as shipped behavior.

### Extension boundary

Extensions can register tools, commands, shortcuts, providers, renderers, UI, persistence entries, and lifecycle middleware. Project-local extensions are trust-gated. The extension API is intentionally outside the core loop rather than a fork of it.

## OpenCode

### Package boundaries

| Layer | Responsibility | Official source |
|---|---|---|
| `schema` | Effect schemas and durable session/message/part/event types | [`schema session`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/schema/src/v1/session.ts) |
| `core` | Runtime services and service-layer infrastructure | [`core session`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/core/src/v1/session.ts) |
| `protocol` | Typed HTTP API groups and middleware | [`protocol API`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/protocol/src/api.ts) |
| `server` | HTTP route and handler assembly over core services | [`server routes`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/server/src/routes.ts) |
| `opencode` | Full runtime: config, agents, sessions, tools, plugins, LLM, MCP, database, HTTP | [`opencode`](https://github.com/anomalyco/opencode/tree/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/opencode) |
| `client` | Generated HTTP client over the protocol contract | [`client contract`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/client/src/contract.ts) |
| `plugin` | Public hooks and custom-tool types | [`plugin API`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/plugin/src/index.ts) |
| `sdk/js` | Generated JavaScript SDK and server-launch helpers | [`SDK client`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/sdk/js/src/v2/client.ts) |
| `cli` / `tui` | CLI lifecycle and Solid/OpenTUI client | [`CLI`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/cli/src/index.ts) |

### Runtime flow

1. `SessionPrompt.runLoop` loads messages, resolves agent/model, handles subtasks and compaction, and creates an assistant message.
2. `SessionTools.resolve` adapts built-in, plugin, and MCP tools into AI SDK tools.
3. `SessionProcessor.process` streams events, persists text/reasoning/tool parts, retries errors, tracks snapshots, and returns `compact`, `stop`, or `continue`.
4. Tool context carries session ID, abort signal, agent, messages, metadata, and the permission `ask` bridge.
5. Protocol, server, client, SDK, and TUI share typed contracts; TUI state is a reconnectable projection over server events.

### Permissions and subagents

- Permission rules use `allow`, `ask`, and `deny`; the last matching wildcard rule wins.
- Agent and session permissions are merged at tool execution time.
- `ask()` emits a permission event and waits on a deferred reply.
- Subagents inherit parent deny and external-directory rules; `task` and `todowrite` require explicit permission.
- Permissions are UX controls, not an OS sandbox.

### Plugin and config boundary

- Tool registry loads built-ins, project-local tools, plugin tools, and MCP tools.
- Plugin hooks can transform config, messages, tool calls, provider behavior, permissions, compaction, and TUI behavior.
- Config loading merges global, project, environment, remote well-known, managed, account, and auto-discovered `.opencode` configuration.
- The plugin loader validates file/npm origins and compatibility before importing.

## Direct Comparison

| Dimension | Pi | OpenCode |
|---|---|---|
| Agent core | Small standalone `Agent`; harness adds persistence | Session processor is integrated into application runtime |
| Persistence | Append-only JSONL tree with `id`/`parentId` | Typed message/part/session data with server-side persistence and snapshots |
| Compaction | Harness projection over durable transcript | Prompt loop and processor manage compaction and replay |
| Tool execution | Core loop, extension hooks, parallel default | Registry -> AI SDK bridge -> Effect runtime -> permission bridge |
| Extensibility | Code-first TypeScript extensions and resources | Declarative config plus plugins/custom tools/MCP |
| Subagents | Not a built-in coding-agent feature; extension or process composition | Built-in agents/subagents with inherited permissions |
| Permission model | No built-in permission popup; host permissions apply | `allow`/`ask`/`deny`, but no OS isolation |
| Client shape | Interactive, print/JSON, RPC, SDK | TUI client, HTTP server, CLI, SDK, web/IDE surfaces |
| UI ownership | `pi-tui` is a reusable rendering package | TUI is a client over server/SDK contracts |

## Context7 Cross-check

- Pi library: `/earendil-works/pi`
- Pi docs candidate: `/websites/pi_dev`
- OpenCode library: `/anomalyco/opencode`
- OpenCode plugin docs: `/websites/opencode_ai_plugins`
- OpenCode SDK: `/anomalyco/opencode-sdk-js`

Context7 corroborated `AgentSession`, Pi persistence layering, OpenCode TUI ownership, the server/client boundary, `SessionTools.resolve`, custom tools, plugin hooks, and compaction hooks. The source refs above are authoritative for the final claims.
