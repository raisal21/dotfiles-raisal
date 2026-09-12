#!/usr/bin/env bash
# Verify the pinned Pi runtime without printing credentials or session contents.
set -euo pipefail

DOTFILES="${DOTFILES:-${HOME}/dotfiles}"
MANIFEST="${DOTFILES}/pi/runtime-manifest.json"
AGENT_DIR="${HOME}/.pi/agent"
WORKFLOW_DIR="${PI_DYNAMIC_WORKFLOWS_DIR:-${AGENT_DIR}/npm/node_modules/@quintinshaw/pi-dynamic-workflows}"
PROJECT_DIR="${1:-}"

failures=0
warnings=0

ok() { printf 'OK   %s\n' "$*"; }
warn() { warnings=$((warnings + 1)); printf 'WARN %s\n' "$*"; }
fail() { failures=$((failures + 1)); printf 'FAIL %s\n' "$*" >&2; }

if [[ ! -f "${MANIFEST}" ]]; then
  fail "runtime manifest missing: ${MANIFEST}"
  exit 1
fi

read_manifest() {
  python3 - "$MANIFEST" "$1" <<'PY'
import json
import sys

path, key = sys.argv[1:]
value = json.load(open(path, encoding="utf-8"))
for part in key.split('.'):
    value = value[part]
print(value)
PY
}

EXPECTED_PI="$(read_manifest runtime.pi)"
EXPECTED_NODE="$(read_manifest runtime.node)"
EXPECTED_NPM="$(read_manifest runtime.npm)"

if ! python3 - "${MANIFEST}" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
expected = {
    ("modelRouting", "advisor"): "openai-codex/gpt-6-astra:medium",
    ("modelRouting", "executor"): "openai-codex/gpt-5.6-luna:max",
    ("modelRouting", "deepResearch", "Queries"): "openai-codex/gpt-6-astra:medium",
    ("modelRouting", "deepResearch", "Gather"): "openai-codex/gpt-5.6-luna:max",
    ("modelRouting", "deepResearch", "Verify"): "openai-codex/gpt-5.6-luna:max",
    ("modelRouting", "deepResearch", "Report"): "openai-codex/gpt-5.6-luna:max",
    ("modelRouting", "jobHunting", "validation"): "openai-codex/gpt-6-astra:medium",
    ("modelRouting", "jobHunting", "query"): "openai-codex/gpt-6-astra:medium",
    ("modelRouting", "jobHunting", "worker"): "openai-codex/gpt-5.6-luna:max",
    ("modelRouting", "jobHunting", "pdfAudit"): "openai-codex/gpt-6-astra:medium",
    ("modelRouting", "jobHunting", "approval"): "openai-codex/gpt-6-astra:medium",
    ("routingPolicy", "plannerAdvisor"): "openai-codex/gpt-6-astra:medium",
    ("routingPolicy", "tokenHeavyExecutor"): "openai-codex/gpt-5.6-luna:max",
    ("routingPolicy", "largeInputOverride"): "openai-codex/gpt-5.6-luna:max",
}
expected_literals = {
    ("jobHuntingWorkflow", "savedName"): "job-hunting-batch",
    ("jobHuntingWorkflow", "projectRelativeSource"): ".pi/workflows/job-hunting-batch.js",
    ("jobHuntingWorkflow", "registrationScript"): "scripts/register-job-hunting-workflow.sh",
    ("jobHuntingWorkflow", "maxJobs"): 10,
    ("jobHuntingWorkflow", "queryAgentsPerBatch"): 1,
    ("jobHuntingWorkflow", "workerAgentsPerJob"): 1,
    ("jobHuntingWorkflow", "pdfAuditAgentsPerBatch"): 1,
    ("jobHuntingWorkflow", "maxConcurrentWorkers"): 10,
    ("jobHuntingWorkflow", "maxAgentCallsPerFullBatch"): 12,
    ("jobHuntingWorkflow", "retryLimit"): 1,
}
expected.update(expected_literals)

failures = 0
for path, expected_value in expected.items():
    value = manifest
    try:
        for part in path:
            value = value[part]
    except (KeyError, TypeError):
        value = None
    label = ".".join(path)
    if value != expected_value:
        print(f"FAIL routing {label}: {value!r}; expected {expected_value!r}")
        failures += 1
    else:
        print(f"OK   routing {label}: {value}")
sys.exit(1 if failures else 0)
PY
then
  failures=$((failures + 1))
fi

actual_pi="$(pi --version 2>/dev/null || true)"
actual_node="$(node --version 2>/dev/null || true)"
actual_npm="$(npm --version 2>/dev/null || true)"

[[ "${actual_pi}" == "${EXPECTED_PI}" ]] && ok "Pi ${actual_pi}" || fail "Pi ${actual_pi:-missing}; expected ${EXPECTED_PI}"
[[ "${actual_node}" == "v${EXPECTED_NODE}" ]] && ok "Node ${actual_node}" || fail "Node ${actual_node:-missing}; expected v${EXPECTED_NODE}"
[[ "${actual_npm}" == "${EXPECTED_NPM}" ]] && ok "npm ${actual_npm}" || fail "npm ${actual_npm:-missing}; expected ${EXPECTED_NPM}"

check_link() {
  local target="$1" source="$2" label="$3"
  if [[ ! -L "${target}" ]]; then
    fail "${label} is not a symlink: ${target}"
    return
  fi
  if [[ "$(readlink -f "${target}")" != "$(readlink -f "${source}")" ]]; then
    fail "${label} points to $(readlink -f "${target}") instead of ${source}"
    return
  fi
  ok "${label} link"
}

check_link "${AGENT_DIR}/settings.json" "${DOTFILES}/pi/settings.json" "Pi settings"
check_link "${AGENT_DIR}/extensions" "${DOTFILES}/pi/extensions" "Pi extensions"
check_link "${AGENT_DIR}/advisor.json" "${DOTFILES}/pi/advisor.json" "Pi Advisor profile"

if [[ ! -f "${WORKFLOW_DIR}/package.json" ]]; then
  fail "pi-dynamic-workflows package missing: ${WORKFLOW_DIR}"
else
  actual_workflow="$(python3 - "${WORKFLOW_DIR}/package.json" <<'PY'
import json
import sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])
PY
)"
  [[ "${actual_workflow}" == "3.10.1" ]] && ok "pi-dynamic-workflows ${actual_workflow}" || fail "pi-dynamic-workflows ${actual_workflow}; expected 3.10.1"
fi

if [[ -f "${WORKFLOW_DIR}/src/deep-research.ts" && -f "${WORKFLOW_DIR}/dist/deep-research.js" ]]; then
  grep -q "openai-codex/gpt-6-astra:medium" "${WORKFLOW_DIR}/src/deep-research.ts" \
    && grep -q "openai-codex/gpt-5.6-luna:max" "${WORKFLOW_DIR}/src/deep-research.ts" \
    && grep -q "openai-codex/gpt-6-astra:medium" "${WORKFLOW_DIR}/dist/deep-research.js" \
    && grep -q "openai-codex/gpt-5.6-luna:max" "${WORKFLOW_DIR}/dist/deep-research.js" \
    && ok "deep-research routing patch" \
    || fail "deep-research routing patch markers missing"
else
  fail "deep-research patch targets missing"
fi

compatibility_warning_count="$(python3 - "${MANIFEST}" <<'PY'
import json
import sys
print(len(json.load(open(sys.argv[1], encoding="utf-8")).get("compatibilityWarnings", [])))
PY
)"
warnings=$((warnings + compatibility_warning_count))

if ! python3 - "${MANIFEST}" "${AGENT_DIR}" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
agent_dir = Path(sys.argv[2])
failures = 0

for spec in manifest["packages"]:
    if spec.startswith("npm:"):
        match = re.fullmatch(r"npm:(?P<name>@[^/]+/[^@]+|[^@]+)@(?P<version>.+)", spec)
        if not match:
            print(f"FAIL malformed npm spec: {spec}")
            failures += 1
            continue
        package_json = agent_dir / "npm" / "node_modules" / match.group("name") / "package.json"
        if not package_json.is_file():
            print(f"FAIL missing package: {spec}")
            failures += 1
            continue
        actual = json.load(open(package_json, encoding="utf-8"))["version"]
        if actual != match.group("version"):
            print(f"FAIL {match.group('name')} {actual}; expected {match.group('version')}")
            failures += 1
        else:
            print(f"OK   {match.group('name')} {actual}")
    elif spec.startswith("git:"):
        match = re.fullmatch(r"git:(?P<url>.+)@(?P<ref>[0-9a-f]{40})", spec)
        if not match:
            print(f"FAIL malformed git spec: {spec}")
            failures += 1
            continue
        parts = match.group("url").split("/")
        checkout = agent_dir / "git" / Path(*parts)
        if not checkout.is_dir():
            print(f"FAIL missing git package checkout: {spec}")
            failures += 1
            continue
        actual = subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"], text=True).strip()
        dirty = subprocess.check_output(["git", "-C", str(checkout), "status", "--porcelain"], text=True)
        if actual != match.group("ref"):
            print(f"FAIL {spec.split('@')[0]} checkout {actual}; expected {match.group('ref')}")
            failures += 1
        elif dirty:
            print(f"FAIL dirty git checkout: {checkout}")
            failures += 1
        else:
            print(f"OK   git checkout {actual}")

for warning in manifest.get("compatibilityWarnings", []):
    print(f"WARN compatibility: {warning['package']} — {warning['reason']}")

sys.exit(1 if failures else 0)
PY
then
  failures=$((failures + 1))
fi

if [[ -f "${DOTFILES}/pi/extensions/bm25-search/index.ts" && ! -d "${DOTFILES}/pi/extensions/bm25-search/node_modules/fast-bm25" ]]; then
  fail "BM25 extension dependencies are not installed"
elif [[ -d "${DOTFILES}/pi/extensions/bm25-search/node_modules/fast-bm25" ]]; then
  ok "BM25 extension dependencies"
fi

if command -v latexmk >/dev/null 2>&1; then
  ok "latexmk available"
else
  warn "latexmk unavailable; PDF validation will not run on this laptop"
fi

if [[ -n "${PROJECT_DIR}" ]]; then
  if [[ -d "${PROJECT_DIR}" && -f "${PROJECT_DIR}/REPRODUCIBILITY.md" ]]; then
    ok "job-hunting reproducibility contract found"
  else
    warn "job-hunting project contract not found at ${PROJECT_DIR}"
  fi

  if [[ -f "${PROJECT_DIR}/.pi/workflows/job-hunting-batch.js" ]]; then
    saved_workflow_path="$(python3 - "${PROJECT_DIR}" <<'PY'
import hashlib
import re
import sys
from pathlib import Path

project = Path(sys.argv[1]).resolve()
slug = re.sub(r"[^a-z0-9._-]+", "-", project.name.lower()).strip("-")[:48] or "project"
key = f"{slug}-{hashlib.sha256(str(project).encode()).hexdigest()[:12]}"
print(Path.home() / ".pi" / "workflows" / "projects" / key / "saved" / "job-hunting-batch.json")
PY
)"
    if [[ ! -f "${saved_workflow_path}" ]]; then
      fail "saved job-hunting workflow missing: ${saved_workflow_path}"
    elif ! python3 - "${saved_workflow_path}" "${PROJECT_DIR}/.pi/workflows/job-hunting-batch.js" <<'PY'
import json
import sys
from pathlib import Path

saved = json.load(open(sys.argv[1], encoding="utf-8"))
source = Path(sys.argv[2]).read_text(encoding="utf-8")
if saved.get("name") != "job-hunting-batch" or saved.get("script") != source:
    raise SystemExit(1)
PY
    then
      fail "saved job-hunting workflow is stale or invalid"
    else
      ok "saved job-hunting workflow registration"
    fi
  else
    fail "versioned job-hunting workflow source missing"
  fi
fi

if (( failures > 0 )); then
  printf 'Preflight failed with %d failure(s) and %d warning(s).\n' "${failures}" "${warnings}" >&2
  exit 1
fi
printf 'Preflight passed with %d warning(s).\n' "${warnings}"
