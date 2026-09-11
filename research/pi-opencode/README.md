# Pi vs OpenCode Research

## Run Metadata

- Research cutoff: `2026-09-09`
- Evidence collection: parallel research agents plus Context7 and direct official-source checks
- Local workspace: `/home/raisal/dotfiles`
- Scope: code architecture, philosophy, ecosystem, package risk, local baseline, and release archaeology
- Current Pi code ref: `6160683a4a8012f0d1cd30c145df18b4ca6f5176`
- Pi release ref: `v0.85.1`, commit `d981de1229ef899957bbe968bc8dcda02a21f477`
- Current OpenCode code ref: `dff8fbc149fb7492e4f07b713ac31ea70d9a541c`
- OpenCode stable release observed: `v1.18.29`, released `2026-09-04T23:47:16Z`

## Identity

- Pi current repository: `https://github.com/earendil-works/pi`
- Pi historical repository: `https://github.com/badlogic/pi-mono`
- OpenCode current repository: `https://github.com/anomalyco/opencode`
- OpenCode archived Go-era repository: `https://github.com/opencode-ai/opencode`
- Historical repository aliases are not treated as separate products without ancestry checks.

## Source Precedence

1. Pinned source code and immutable commit/tag
2. Official documentation and release/changelog source
3. npm/GitHub registry metadata
4. Context7 indexed documentation
5. Secondary commentary

Context7 is used for orientation and API cross-checking. Important claims are corroborated against pinned official source.

## Findings Status

- Architecture: collected and source-linked.
- Philosophy/governance: collected with unresolved ambiguities listed.
- Ecosystem: preliminary shortlist and risk signals collected; candidates remain unapproved until a disposable pilot.
- Local baseline: collected read-only.
- OpenCode release archaeology: collected at milestone level.
- Pi release archaeology: repeated independently and reconciled in `pi-release-archeology.md`.

## Artifacts

- `architecture.md`: code and runtime comparison.
- `philosophy-and-governance.md`: design intent, defaults, trust, and governance.
- `local-baseline.md`: dotfiles and installed configuration inventory.
- `ecosystem-shortlist.md`: candidates, native alternatives, and risk disposition.
- `release-timeline.md`: normalized OpenCode milestones and Pi summary.
- `pi-release-archeology.md`: Pi launch crosswalk, package lineage, inventory coverage, and feature milestones.
- `pi-release-inventory.csv`: 274 numbered changelog rows plus a separate `Unreleased` row.
- `pi-release-feature-events.csv`: 2,898 meaningful changelog event rows plus 11 explicit empty-release rows.
- `pi-release-boundaries.csv`: pre-`0.10.0` source/package/tag/public-launch crosswalk.
- `evidence-ledger.md`: claim-to-source index and unresolved conflicts.

## Important Boundary

The research does not install or enable new Pi/OpenCode packages. Plugin and package recommendations below are research dispositions, not approval to run them on the host.
