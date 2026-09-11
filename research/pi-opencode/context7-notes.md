# Context7 Notes

## Resolution

| Library | Resolved ID | Reputation | Benchmark |
|---|---|---|---:|
| Pi | `/earendil-works/pi` | High | 81.78 |
| Pi docs | `/websites/pi_dev` | High | 75.33 |
| OpenCode | `/anomalyco/opencode` | High | 87.82 |
| OpenCode plugins | `/websites/opencode_ai_plugins` | High | 72.95 |
| OpenCode SDK | `/anomalyco/opencode-sdk-js` | High | 72.36 |

## Queries Executed

- Pi architecture: package boundaries, agent loop, `AgentSession`, `ResourceLoader`, `SessionManager`, JSONL, compaction, and extension lifecycle.
- OpenCode architecture: client/server, core/application packages, session runtime, generated protocol/SDK, config discovery, and plugin loading.
- OpenCode plugins: local/npm discovery, custom tools, event hooks, plugin context, SDK access, compaction hooks, dependencies, and reload behavior.

## Useful Results

- Pi `Agent` owns the core runtime while `AgentSession` adds persistence, compaction, model state, extension dispatch, and session operations.
- Pi `AgentSession` exposes prompt, steer, follow-up, subscription, tree navigation, compaction, abort, and disposal surfaces.
- OpenCode TUI owns presentation while server/SDK owns session, message, provider, permission, and tool domain data.
- OpenCode `SessionTools.resolve` bridges registered tools into AI SDK tools with session, abort, agent, permission, and metadata context.
- OpenCode plugins can register custom tools and hook tool execution and compaction.

## Verification Rule

Context7 output is treated as `DISCOVERY`/`CROSS_CHECK`. Final claims use the pinned GitHub/docs links in `architecture.md` and `evidence-ledger.md`. Context7-only claims are not used for recommendations.
