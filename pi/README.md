# Pi Runtime

The files in this directory are the versioned, non-secret Pi runtime contract used by both laptops.

## Managed files

- `settings.json` — pinned package specs and explicit active-extension allowlist.
- `runtime-manifest.json` — Pi/Node/npm versions, package refs, phase-level model routing, compatibility warnings, and local-only state.
- `advisor.json` — Advisor routing profile; Astra medium plans/reviews and Luna max executes token-heavy work.
- `extensions/` — versioned active local extensions and dependency manifests.

## Bootstrap

Run from the dotfiles checkout:

```bash
./scripts/bootstrap.sh
```

Bootstrap links settings, extensions, and the Advisor profile into `~/.pi/agent`, installs the managed BM25 dependency with `npm ci --ignore-scripts`, applies the version-checked workflow routing patch, and runs fail-closed preflight. Register the project workflow after the job-hunting checkout is available:

```bash
./scripts/register-job-hunting-workflow.sh /path/to/job-hunting
```

The registration copies the versioned project source into the project-scoped local saved-workflow record; it does not replace the repository source.

## Preflight

```bash
./scripts/pi-preflight.sh /path/to/job-hunting
```

The preflight checks exact Pi/Node/npm versions, package versions, the pinned `pi-vim` commit, managed symlinks, workflow patch markers, BM25 dependencies, LaTeX availability, the project reproducibility contract, the declared phase-routing map, and a current saved `job-hunting-batch` registration when a project path is supplied. It never prints credentials.

Known compatibility warnings are intentional and recorded in `runtime-manifest.json`; they block implicit upgrades but do not block the current pinned runtime.

## Model routing

- Astra (`openai-codex/gpt-6-astra:medium`) handles intake, planning, query/decomposition design, task routing, and compact advisor/adjudication work.
- Luna (`openai-codex/gpt-5.6-luna:max`) handles evidence extraction, source gathering, synthesis, drafting, PDF/content QA, and long reports.
- A manifest entry is not enforcement by itself. Versioned workflow phases must pass the model explicitly; static preflight markers do not prove effective runtime selection.
- The option analysis and rationale are archived in `job-hunting/decisions/model-routing-policy.md`.

## Not tracked here

Do not add provider credentials, SSH keys, browser profiles, Pi sessions, workflow journals, cached results, or generated `node_modules`.
