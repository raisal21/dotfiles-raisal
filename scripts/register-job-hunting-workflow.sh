#!/usr/bin/env bash
# Register the versioned job-hunting workflow as a project-scoped Pi command.
# Usage: register-job-hunting-workflow.sh /path/to/job-hunting
set -euo pipefail

DOTFILES="${DOTFILES:-${HOME}/dotfiles}"
PROJECT_DIR="${1:-${JOB_HUNTING_DIR:-}}"
SOURCE="${PROJECT_DIR}/.pi/workflows/job-hunting-batch.js"

if [[ -z "${PROJECT_DIR}" ]]; then
  echo "ERROR: provide the job-hunting project path or set JOB_HUNTING_DIR" >&2
  exit 1
fi
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "ERROR: project directory not found: ${PROJECT_DIR}" >&2
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
script = source.read_text(encoding="utf-8")
slug = re.sub(r"[^a-z0-9._-]+", "-", project_dir.name.lower()).strip("-")[:48] or "project"
key = f"{slug}-{hashlib.sha256(str(project_dir).encode()).hexdigest()[:12]}"
saved_dir = Path.home() / ".pi" / "workflows" / "projects" / key / "saved"
saved_dir.mkdir(parents=True, exist_ok=True)
target = saved_dir / "job-hunting-batch.json"
record = {
    "name": "job-hunting-batch",
    "description": "Run a bounded, evidence-traced job application batch through planning, drafting, QA, and approval readiness.",
    "script": script,
    "parameters": {
        "batchId": {"type": "string", "description": "Immutable batch identifier", "required": True},
        "jobs": {"type": "array", "description": "At most three objects with jobId and jobSource paths", "required": True},
    },
    "savedAt": datetime.now(timezone.utc).isoformat(),
}
fd, tmp_name = tempfile.mkstemp(prefix="job-hunting-batch.", suffix=".json.tmp", dir=saved_dir)
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
