# Evidence Ledger

| Claim ID | Claim | Status | Primary evidence |
|---|---|---|---|
| `PI-ARCH-001` | Pi separates provider API, agent core, coding harness, and TUI | `VERIFIED` | [Pi packages](https://github.com/earendil-works/pi/tree/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages) |
| `PI-ARCH-002` | `AgentSession` adds persistence and harness behavior over `Agent` | `VERIFIED` | [agent-session.ts](https://github.com/earendil-works/pi/blob/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/src/core/agent-session.ts) |
| `PI-ARCH-003` | Pi sessions are append-only JSONL trees | `VERIFIED` | [session-format.md](https://github.com/earendil-works/pi/blob/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/docs/session-format.md) |
| `OC-ARCH-001` | OpenCode has typed protocol/server/client/SDK boundaries | `VERIFIED` | [protocol](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/protocol/src/api.ts), [client](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/client/src/contract.ts) |
| `OC-ARCH-002` | OpenCode tools pass through `SessionTools.resolve` and a permission bridge | `VERIFIED` | [session/tools.ts](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/opencode/src/session/tools.ts) |
| `OC-ARCH-003` | OpenCode config merges project/global/managed/remote sources | `VERIFIED` | [config.ts](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/packages/opencode/src/config/config.ts) |
| `PHIL-001` | Pi is minimal/core-first and OpenCode is integrated/product-first | `INFERRED` | Pi [README](https://raw.githubusercontent.com/earendil-works/pi/6160683a4a8012f0d1cd30c145df18b4ca6f5176/packages/coding-agent/README.md); OpenCode [README](https://raw.githubusercontent.com/anomalyco/opencode/dff8fbc149fb7492e4f07b713ac31ea70d9a541c/README.md) |
| `SEC-001` | Neither project permission model is an OS sandbox | `VERIFIED` | Pi [security](https://pi.dev/docs/latest/security); OpenCode [permissions](https://opencode.ai/docs/permissions/) |
| `LOCAL-001` | `@opencode-ai/plugin` in learn is a dependency, not a loaded plugin declaration | `VERIFIED` | `opencode-learn/package.json:2-4`, `opencode-learn/opencode.json:1-33` |
| `LOCAL-002` | Global OpenCode config declares DCP and vim registry plugins | `VERIFIED` | `opencode/opencode.json:176-179` |
| `ECO-PI-001` | Pi permission system fails closed at an in-process tool boundary | `VERIFIED` | [boundary](https://unpkg.com/@gotgenes/pi-permission-system@31.1.3/src/handlers/tool-call-boundary.ts) |
| `ECO-OC-001` | `opencode-pty` web routes can bypass model permission checks for process creation | `VERIFIED` | [sessions handler](https://unpkg.com/opencode-pty@0.3.6/dist/src/web/server/handlers/sessions.js), [permissions](https://unpkg.com/opencode-pty@0.3.6/dist/src/plugin/pty/permissions.js) |
| `ECO-OC-002` | DCP auto-update mutates cache/config and queries npm | `VERIFIED` | [update.ts](https://unpkg.com/@tarquinen/opencode-dcp@3.1.15/lib/update.ts) |
| `PI-REL-001` | Pi v0.0.1 is a scaffold and v0.0.2 contains coding-agent | `VERIFIED` | [v0.0.1](https://raw.githubusercontent.com/earendil-works/pi/v0.0.1/package.json), [v0.0.2](https://raw.githubusercontent.com/earendil-works/pi/v0.0.2/packages/coding-agent/package.json) |
| `PI-REL-002` | Current main Pi changelog labels `0.10.0` as `Initial public release` | `VERIFIED` | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `PI-REL-003` | Pi package scope migrates from Mario to Earendil at `0.74.0` | `VERIFIED` | [migration commit](https://github.com/earendil-works/pi/commit/551385e40946d5531e823edea533410c816926ce) |
| `PI-REL-004` | Main Pi changelog has 274 numbered entries through `0.85.1` and 2,898 meaningful event rows | `VERIFIED` and materialized in CSV | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md), [`inventory`](./pi-release-inventory.csv), [`events`](./pi-release-feature-events.csv) |
| `OC-REL-001` | OpenCode `v1.0.0` rewrote the TUI from Go/Bubble Tea to OpenTUI/Zig/SolidJS | `VERIFIED` | [release](https://github.com/anomalyco/opencode/releases/tag/v1.0.0) |

## Unresolved or Blocked

- Pi release inventory and feature-event CSVs are materialized; raw release-body snapshots are not vendored and remain linked to immutable official URLs.
- GitHub API `403` prevented relying on API pagination; Atom feeds, raw tags, release pages, changelog, and npm packuments were used instead.
- OpenCode project-trust and plugin-approval behavior needs direct runtime/source confirmation.
- Candidate package dispositions require disposable execution before becoming permanent recommendations.
