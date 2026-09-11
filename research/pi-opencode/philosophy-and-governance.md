# Philosophy and Governance

## Comparison

| Dimension | Pi | OpenCode |
|---|---|---|
| Core philosophy | Minimal and extensible; workflow features outside the harness belong in extensions | Integrated product with built-in agents, permissions, MCP, LSP, plugins, server mode, and multiple clients |
| Customization | Code-first TypeScript extensions, skills, prompts, themes, packages, and CLI composition | Declarative JSON/JSONC, Markdown agents/rules/skills, plugins, custom tools, and MCP |
| Project trust | Project-local resources/packages/extensions are trust-gated; trust is not a sandbox | Project and `.opencode` config is merged automatically in reviewed docs; equivalent trust prompt is unresolved |
| Permissions | No built-in permission system; launched process permissions apply | `allow`/`ask`/`deny` rules with agent/session merging; still not sandboxing |
| Package trust | Official docs warn that packages/extensions have full system access | Plugins auto-load or install and receive SDK/shell capabilities; approval semantics remain partly undocumented |
| Subagents | No dedicated built-in plan/subagent feature; compose through extensions, Bash, or tmux | Built-in Build/Plan agents and General/Explore/Scout subagents |
| Client model | Interactive, print/JSON, RPC, and SDK embedding | TUI over HTTP server, CLI, OpenAPI, SDK, web/IDE, and server mode |
| Intended user | Individual terminal user who wants an observable harness to shape | Terminal, desktop, web/IDE, team, and enterprise users |
| License | MIT | MIT |

## Evidence

- Pi README and coding-agent docs: [`coding-agent README`](https://raw.githubusercontent.com/earendil-works/pi/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/README.md)
- Pi security and package docs: [`security`](https://raw.githubusercontent.com/earendil-works/pi/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/docs/security.md), [`packages`](https://raw.githubusercontent.com/earendil-works/pi/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/docs/packages.md)
- Pi maintainer rationale: [Mario Zechner, what if you do not need MCP](https://mariozechner.at/posts/2025-11-02-what-if-you-dont-need-mcp/)
- OpenCode agents/config/plugins/permissions: [agents](https://opencode.ai/docs/agents/), [config](https://opencode.ai/docs/config/), [plugins](https://opencode.ai/docs/plugins/), [permissions](https://opencode.ai/docs/permissions/)
- OpenCode security: [`SECURITY.md`](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/SECURITY.md)
- Governance: [Pi CONTRIBUTING](https://raw.githubusercontent.com/earendil-works/pi/6160683a4a8012f0d1cd30c145df18b4ca6f5176/CONTRIBUTING.md), [OpenCode CONTRIBUTING](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/CONTRIBUTING.md)

## Interpretation

- Pi minimizes the trusted core and moves workflow design into user-owned code.
- OpenCode centralizes more workflow policy into agents, config, permissions, and server/client contracts.
- Both projects are extensible and unsandboxed by default; the difference is where policy is expressed, not whether host-level risk disappears.

## Unresolved

- OpenCode plugin approval/trust behavior beyond documented auto-load/install is not fully established.
- OpenCode project trust behavior needs direct runtime/source verification.
- Pi durability documents include normative unfinished work; shipped behavior must be tied to implementation refs.
- Release cadence and complete governance charters are not established by the reviewed sources.
