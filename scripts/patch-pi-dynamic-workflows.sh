#!/usr/bin/env bash
# Apply the version-pinned deep-research model routing patch.
# The package loads dist/ at runtime; src/ is patched too so a later local
# rebuild does not silently discard the routing policy.

set -euo pipefail

PACKAGE_DIR="${PI_DYNAMIC_WORKFLOWS_DIR:-${HOME}/.pi/agent/npm/node_modules/@quintinshaw/pi-dynamic-workflows}"
EXPECTED_VERSION="3.10.1"
SRC_FILE="${PACKAGE_DIR}/src/deep-research.ts"
DIST_FILE="${PACKAGE_DIR}/dist/deep-research.js"

if [[ ! -f "${PACKAGE_DIR}/package.json" ]]; then
  echo "ERROR: pi-dynamic-workflows package not found: ${PACKAGE_DIR}" >&2
  exit 1
fi

version="$(python3 - "${PACKAGE_DIR}/package.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["version"])
PY
)"

if [[ "${version}" != "${EXPECTED_VERSION}" ]]; then
  echo "ERROR: unsupported pi-dynamic-workflows version ${version}; expected ${EXPECTED_VERSION}" >&2
  echo "Update this patch after reviewing the upstream package changes." >&2
  exit 1
fi

for file in "${SRC_FILE}" "${DIST_FILE}"; do
  if [[ ! -f "${file}" ]]; then
    echo "ERROR: expected package file not found: ${file}" >&2
    exit 1
  fi
done

if python3 - "${SRC_FILE}" "${DIST_FILE}" <<'PY'
from pathlib import Path
import sys

old = """  phases: [
    { title: 'Queries' },
    { title: 'Gather' },
    { title: 'Verify' },
    { title: 'Report' },
  ],"""
new = """  phases: [
    { title: 'Queries', model: 'openai-codex/gpt-6-astra:medium' },
    { title: 'Gather', model: 'openai-codex/gpt-5.6-luna:max' },
    { title: 'Verify', model: 'openai-codex/gpt-5.6-luna:max' },
    { title: 'Report', model: 'openai-codex/gpt-5.6-luna:max' },
  ],"""

for value in sys.argv[1:]:
    content = Path(value).read_text(encoding="utf-8")
    if new not in content or old in content:
        raise SystemExit(1)
PY
then
  echo "already patched: ${PACKAGE_DIR}"
  exit 0
fi

backup_dir="${PI_DYNAMIC_WORKFLOWS_BACKUP_DIR:-${TMPDIR:-/tmp}/pi-dynamic-workflows-patch-backups}"
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${backup_dir}"
cp -p "${SRC_FILE}" "${backup_dir}/deep-research.ts.${stamp}.bak"
cp -p "${DIST_FILE}" "${backup_dir}/deep-research.js.${stamp}.bak"

echo "backed up patch targets to ${backup_dir}"

python3 - "${SRC_FILE}" "${DIST_FILE}" <<'PY'
from pathlib import Path
import sys

old = """  phases: [
    { title: 'Queries' },
    { title: 'Gather' },
    { title: 'Verify' },
    { title: 'Report' },
  ],"""
new = """  phases: [
    { title: 'Queries', model: 'openai-codex/gpt-6-astra:medium' },
    { title: 'Gather', model: 'openai-codex/gpt-5.6-luna:max' },
    { title: 'Verify', model: 'openai-codex/gpt-5.6-luna:max' },
    { title: 'Report', model: 'openai-codex/gpt-5.6-luna:max' },
  ],"""

files = [Path(value) for value in sys.argv[1:]]
contents = {path: path.read_text(encoding="utf-8") for path in files}

for path, content in contents.items():
    already_patched = new in content and old not in content
    if already_patched:
        continue
    if old not in content:
        raise SystemExit(f"ERROR: routing signature not found in {path}; refusing to patch upstream drift")
    if new in content:
        raise SystemExit(f"ERROR: ambiguous routing signature in {path}; refusing to patch")

for path, content in contents.items():
    path.write_text(content.replace(old, new, 1), encoding="utf-8")
PY

echo "patched: ${PACKAGE_DIR} (Queries=Astra medium; Gather/Verify/Report=Luna max)"
