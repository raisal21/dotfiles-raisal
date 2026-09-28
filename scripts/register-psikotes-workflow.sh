#!/usr/bin/env bash
# Register the versioned psikotes-generate workflow as a project-scoped Pi command.
# Usage: register-psikotes-workflow.sh /path/to/job-hunting
set -euo pipefail

PROJECT_DIR="${1:-${JOB_HUNTING_DIR:-}}"
SOURCE="${PROJECT_DIR}/.pi/workflows/psikotes-generate.js"

if [[ -z "${PROJECT_DIR}" ]]; then
  echo "ERROR: provide the job-hunting project path or set JOB_HUNTING_DIR" >&2
  exit 1
fi
if [[ ! -f "${SOURCE}" ]]; then
  echo "ERROR: versioned workflow source missing: ${SOURCE}" >&2
  exit 1
fi

python3 - "${PROJECT_DIR}" "${SOURCE}" <<'PY'
import hashlib
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

project_dir = Path(sys.argv[1]).resolve()
source = Path(sys.argv[2]).resolve()
slug = re.sub(r"[^a-z0-9._-]+", "-", project_dir.name.lower()).strip("-")[:48] or "project"
key = f"{slug}-{hashlib.sha256(str(project_dir).encode()).hexdigest()[:12]}"
saved_dir = Path.home() / ".pi" / "workflows" / "projects" / key / "saved"
saved_dir.mkdir(parents=True, exist_ok=True)
target = saved_dir / "psikotes-generate.json"
record = {
    "name": "psikotes-generate",
    "description": "Create psikotes practice items: Luna writes or generates, Sol solves blind, then bank check and lint. Never creates reviewed items.",
    "script": source.read_text(encoding="utf-8"),
    "parameters": {
        "subtest": {"type": "string", "description": "Subtest code or prefix, e.g. zr, ra, wa, cn", "required": True},
        "n": {"type": "number", "description": "Number of items, at most 20 (default 5)", "required": False},
        "mechanism": {"type": "string", "description": "Mechanism code from bank_taxonomy (optional)", "required": False},
        "level": {"type": "number", "description": "Level 1 to 3 (optional)", "required": False},
    },
    "savedAt": datetime.now(timezone.utc).isoformat(),
}
fd, tmp_name = tempfile.mkstemp(prefix="psikotes-generate.", suffix=".json.tmp", dir=saved_dir)
os.close(fd)
tmp = Path(tmp_name)
try:
    tmp.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    if target.exists():
        target.replace(target.with_suffix(".json.bak"))
    tmp.replace(target)
finally:
    if tmp.exists():
        tmp.unlink()
print(f"registered: /{record['name']} -> {target}")
PY
