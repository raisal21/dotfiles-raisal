# Pi Release Archaeology

## Research Boundary

- Cutoff: `2026-09-09`
- Current repository: `https://github.com/earendil-works/pi`
- Historical repository identity: `https://github.com/badlogic/pi-mono`
- Current coding-agent package observed: `@earendil-works/pi-coding-agent@0.85.1`
- Current release commit: `d981de1229ef899957bbe968bc8dcda02a21f477`
- Main coding-agent changelog: [`CHANGELOG.md`](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md)
- Main changelog coverage: 274 numbered entries from `0.10.0` through `0.85.1`, plus `Unreleased`.
- Empty entries preserved in the inventory: `0.80.5`, `0.72.1`, `0.67.68`, `0.65.2`, `0.58.3`, `0.52.1`, `0.50.5`, `0.45.3`, `0.37.8`, `0.37.7`, `0.34.2`.

## Launch Crosswalk

| Layer | Artifact | Date/value | Meaning | Evidence |
|---|---|---|---|---|
| Source inception | Initial commit `a74c5da` | `2025-08-09` | Monorepo ancestry begins | [commit](https://github.com/earendil-works/pi/commit/a74c5da) |
| First Pi package | `@mariozechner/pi-agent@0.5.0` | npm publication observed `2025-08-09` | Public package artifact, not yet coding-agent product | [npm](https://registry.npmjs.org/@mariozechner%2Fpi-agent) |
| Repository scaffold | `v0.0.1` | tag dated `2025-09-09` | Root monorepo; no `packages/coding-agent` | [manifest](https://raw.githubusercontent.com/earendil-works/pi/v0.0.1/package.json) |
| First coding-agent package artifact | `@mariozechner/coding-agent@0.5.45` | npm publication observed `2025-10-22` | Earliest verified installable coding-agent package | [npm](https://registry.npmjs.org/@mariozechner%2Fcoding-agent/0.5.45) |
| First tagged coding-agent source | `v0.0.2` | tag snapshot; root `0.0.2` | Contains `@mariozechner/coding-agent@0.5.47`, binary `coding-agent` | [root](https://raw.githubusercontent.com/earendil-works/pi/v0.0.2/package.json), [package](https://raw.githubusercontent.com/earendil-works/pi/v0.0.2/packages/coding-agent/package.json) |
| Product rename | `@mariozechner/pi-coding-agent` | begins at `0.6.2` | Historical npm package rename; `0.6.1` absent | [npm](https://registry.npmjs.org/@mariozechner%2Fpi-coding-agent/0.6.2) |
| CLI identity | `v0.7.8` / `v0.7.13` | historical | Package/binary identity becomes `pi` | [v0.7.13 manifest](https://raw.githubusercontent.com/earendil-works/pi/v0.7.13/packages/coding-agent/package.json) |
| Maintainer-labeled launch | `0.10.0` | main changelog `2025-11-25`; tagged snapshot/release `2025-11-27` | Current main changelog labels `Initial public release`; immutable tag snapshot is dated `2025-11-27` | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md), [tagged changelog](https://raw.githubusercontent.com/earendil-works/pi/v0.10.0/packages/coding-agent/CHANGELOG.md), [release](https://github.com/earendil-works/pi/releases/tag/v0.10.0) |
| Scope migration | `@mariozechner/pi-coding-agent@0.73.1` -> `@earendil-works/pi-coding-agent@0.74.0` | merge `551385e` | Ownership/package scope transition, not a feature release | [migration commit](https://github.com/earendil-works/pi/commit/551385e40946d5531e823edea533410c816926ce) |
| Current observed release | `@earendil-works/pi-coding-agent@0.85.1` | current at cutoff | No `v1.0.0` observed | [npm](https://registry.npmjs.org/@earendil-works%2Fpi-coding-agent/0.85.1), [commit](https://github.com/earendil-works/pi/commit/d981de1229ef899957bbe968bc8dcda02a21f477) |

`first_launch` is therefore represented by multiple explicit boundaries: source inception, first public installable coding-agent artifact, first tagged coding-agent source, and the maintainer-labeled `0.10.0` public release. No boundary is silently substituted for another.

## Package Lineage

| Period | Package identity | Notes |
|---|---|---|
| Early | `@mariozechner/pi-agent`, `@mariozechner/pi-tui` | Initial package layer |
| Coding agent | `@mariozechner/coding-agent` | `0.5.45` npm artifact; `v0.0.2` source snapshot contains `0.5.47` |
| Historical product | `@mariozechner/pi-coding-agent` | `0.6.2` through `0.73.1`; deprecated in favor of Earendil scope |
| Current product | `@earendil-works/pi-coding-agent` | Begins at `0.74.0`; `0.85.1` observed current |
| Root workspace | `pi-monorepo` | Private root version remains separate from workspace package version |

Do not confuse the unrelated unscoped placeholder `pi-coding-agent@0.0.1` with the Mario/Earendil package lineage.

## High-Impact Feature Timeline

| Version | Feature/event | Category | Evidence |
|---|---|---|---|
| `0.7.7` | `AGENT.md` -> `AGENTS.md`; session-format breaking changes | Config/session | [tagged changelog](https://raw.githubusercontent.com/badlogic/pi-mono/v0.7.13/packages/coding-agent/CHANGELOG.md) |
| `0.9.1` | `pi-agent` -> `pi-agent-core` rename | Package/API | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.10.0` | Current main changelog labels the initial public release boundary | Product launch | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.32.0` | Queue API replaced by `steer()` and `followUp()` | Agent loop/API | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.67.1` | Interactive-only, opt-out anonymous install telemetry | Privacy/operations | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.69.0` | TypeBox 1.x migration and breaking session-replacement semantics | Dependency/session | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.73.1` | Self-update scope migration, interactive OAuth selection, JSONC model config | Distribution/auth/config | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.74.0` | Mario -> Earendil package/repository scope migration | Governance/package | [migration merge](https://github.com/earendil-works/pi/commit/551385e40946d5531e823edea533410c816926ce), [release commit](https://github.com/earendil-works/pi/commit/1eee081e29c1323c40b98db11d0a62b919831881) |
| `0.81.0` | Full provider extensions and local llama.cpp model management | Provider/local model | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.81.1` | Deterministic, checksummed source archives | Supply chain/release | [main changelog](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/CHANGELOG.md) |
| `0.84.0` | Remote-session, protocol, fullscreen, and harness API work begins | Runtime/protocol | [tagged source](https://github.com/earendil-works/pi/releases/tag/v0.84.0) |
| `0.85.0` | Continued remote-session/protocol/harness changes | Runtime/protocol | [tagged source](https://github.com/earendil-works/pi/releases/tag/v0.85.0) |
| `0.85.1` | GPT-6 Astra, faster Alt-wheel scrolling, targeted fixes | Provider/UI/patch | [npm](https://registry.npmjs.org/@earendil-works%2Fpi-coding-agent/0.85.1) |

## Coverage and Reconciliation

- The maintained main changelog covers `0.10.0` through `0.85.1`; early artifacts must be inventoried from tag snapshots, release pages, and npm packuments separately.
- Empty changelog entries remain rows; they are not treated as missing releases.
- `0.80.4` is absent from npm while `0.80.3` and `0.80.5` exist; record this as a registry gap, not an inferred release deletion.
- The current main changelog carries `0.10.0` date `2025-11-25` and the immutable tagged changelog carries `2025-11-27`; both raw values remain in the boundary crosswalk.
- Historical npm timestamp extraction is limited to the packument `time` object; the separate scoped package time endpoint returned `404`.
- Tag date, GitHub release date, npm publication date, and literal changelog date are stored separately.
- Field-specific chronology precedence: npm `time[version]` for package publication, GitHub `published_at` for release publication, annotated tagger date or target commit date for tag creation, and changelog date only as documentary metadata.
- Match records by immutable commit SHA or normalized identity, never by date alone.
- `Unreleased` is a changelog section, not a release row.

The pre-`0.10.0` launch records are materialized separately in [`pi-release-boundaries.csv`](./pi-release-boundaries.csv), because they are not all coding-agent changelog rows.

## Archaeology Result

The repeated archaeology resolves the prior `v0.0.2` conflict: the tag snapshot at the official current repository contains `packages/coding-agent` and `@mariozechner/coding-agent@0.5.47`. The earlier claim that `v0.0.2` lacked that package is rejected for this pinned source.

The release body/publication date for `0.10.0` is not treated as independently verified through the GitHub API because the API lookup returned `404`; the tagged changelog and current main changelog are retained as separate evidence streams.

The defensible comparison ref for current capability is `@earendil-works/pi-coding-agent@0.85.1` against OpenCode `v1.18.29`. Earlier Pi rows explain product and architecture evolution only.
