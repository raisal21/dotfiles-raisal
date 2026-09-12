#!/usr/bin/env bash
# Bootstrap dotfiles on a fresh machine.
# Assumes this repo is cloned to ~/dotfiles.

set -euo pipefail

DOTFILES="${HOME}/dotfiles"
CONFIG="${HOME}/.config"

link_pi_resource() {
  local source="$1"
  local target="$2"
  local label="$3"

  if [[ ! -e "${source}" && ! -L "${source}" ]]; then
    echo "ERROR: ${label} source missing: ${source}" >&2
    return 1
  fi

  mkdir -p "$(dirname "${target}")"
  if [[ -L "${target}" && "$(readlink -f "${target}")" == "$(readlink -f "${source}")" ]]; then
    echo "linked: ${target} -> ${source}"
    return 0
  fi

  if [[ -e "${target}" || -L "${target}" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "${target}" "${backup}"
    echo "backed up existing ${label} to ${backup}"
  fi

  ln -s "${source}" "${target}"
  echo "linked: ${target} -> ${source}"
}

if [[ ! -d "${DOTFILES}" ]]; then
  echo "ERROR: ${DOTFILES} not found. Clone the dotfiles repo there first." >&2
  exit 1
fi

# Backup existing .config if it's a real dir (not already symlinked)
if [[ -d "${CONFIG}" && ! -L "${CONFIG}" ]]; then
  backup="${CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
  echo "Existing ~/.config found. Backing up to ${backup}"
  mv "${CONFIG}" "${backup}"
fi

# Link the entire .config tree
ln -sfn "${DOTFILES}" "${CONFIG}"
echo "linked: ${CONFIG} -> ${DOTFILES}"

# Keep the versioned Pi runtime, extensions, and Advisor profile linked to dotfiles.
PI_AGENT="${HOME}/.pi/agent"
link_pi_resource "${DOTFILES}/pi/settings.json" "${PI_AGENT}/settings.json" "Pi settings"
link_pi_resource "${DOTFILES}/pi/extensions" "${PI_AGENT}/extensions" "Pi extensions"
link_pi_resource "${DOTFILES}/pi/advisor.json" "${PI_AGENT}/advisor.json" "Pi Advisor profile"

# Install dependencies for the managed BM25 extension without running package scripts.
BM25_EXTENSION="${DOTFILES}/pi/extensions/bm25-search"
if [[ ! -d "${BM25_EXTENSION}/node_modules/fast-bm25" ]]; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: npm is required to install BM25 extension dependencies" >&2
    exit 1
  fi
  (cd "${BM25_EXTENSION}" && npm ci --ignore-scripts --no-audit --no-fund)
fi

# Keep a real Windows-readable Kanata config. Native Windows cannot follow a
# WSL symlink such as /home/raisal/dotfiles/kanata/kanata.kbd.
KANATA_SOURCE="${DOTFILES}/kanata/kanata.kbd"
KANATA_TARGET="${KANATA_CONFIG_PATH:-/mnt/c/Users/PC-Windows/Documents/Kanata/kanata.kbd}"
KANATA_DIR="$(dirname "${KANATA_TARGET}")"

if [[ -d "${KANATA_DIR}" ]]; then
  if [[ ! -f "${KANATA_SOURCE}" ]]; then
    echo "ERROR: Kanata source missing: ${KANATA_SOURCE}" >&2
    exit 1
  fi

  if [[ -f "${KANATA_TARGET}" && ! -L "${KANATA_TARGET}" ]] \
    && cmp -s "${KANATA_SOURCE}" "${KANATA_TARGET}"; then
    echo "Kanata config already synced: ${KANATA_TARGET}"
  else
    kanata_tmp="$(mktemp "${KANATA_TARGET}.tmp.XXXXXX")"
    if ! cp -- "${KANATA_SOURCE}" "${kanata_tmp}" \
      || ! cmp -s "${KANATA_SOURCE}" "${kanata_tmp}"; then
      rm -f -- "${kanata_tmp}"
      echo "ERROR: failed to prepare Kanata config: ${KANATA_SOURCE}" >&2
      exit 1
    fi

    kanata_backup=""
    if [[ -e "${KANATA_TARGET}" || -L "${KANATA_TARGET}" ]]; then
      kanata_backup="${KANATA_TARGET}.bak.$(date +%Y%m%d-%H%M%S)-$$"
      while [[ -e "${kanata_backup}" || -L "${kanata_backup}" ]]; do
        kanata_backup="${KANATA_TARGET}.bak.$(date +%Y%m%d-%H%M%S)-$$-$RANDOM"
      done
      if ! mv -- "${KANATA_TARGET}" "${kanata_backup}"; then
        rm -f -- "${kanata_tmp}"
        echo "ERROR: failed to back up existing Kanata config: ${KANATA_TARGET}" >&2
        exit 1
      fi
      echo "backed up existing Kanata config to ${kanata_backup}"
    fi

    if ! mv -f -- "${kanata_tmp}" "${KANATA_TARGET}"; then
      rm -f -- "${kanata_tmp}"
      if [[ -n "${kanata_backup}" ]]; then
        if mv -- "${kanata_backup}" "${KANATA_TARGET}"; then
          echo "restored previous Kanata config: ${KANATA_TARGET}" >&2
        else
          echo "ERROR: failed to restore previous Kanata config; backup remains at ${kanata_backup}" >&2
        fi
      fi
      echo "ERROR: failed to install Kanata config: ${KANATA_TARGET}" >&2
      exit 1
    fi
    echo "copied Kanata config: ${KANATA_SOURCE} -> ${KANATA_TARGET}"
  fi
else
  echo "skipped Kanata config sync: ${KANATA_DIR} not found"
fi

# Optional env vars (see Decision 12 in nvim/napkin.md)
zshrc="${HOME}/.zshrc"
if [[ -f "${zshrc}" ]] && ! grep -q "NOTEBOOK_PATH" "${zshrc}"; then
  cat >> "${zshrc}" <<'EOF'

# Obsidian vault path (consumed by nvim obsidian.lua)
export NOTEBOOK_PATH="/mnt/c/Users/PC-Windows/Documents/wsl-notebook"
EOF
  echo "added NOTEBOOK_PATH to ~/.zshrc (edit if path differs on this machine)"
fi

# Source shell functions that live in the dotfiles repo.
if [[ -f "${zshrc}" ]] && ! grep -Fq 'file-finder.zsh' "${zshrc}"; then
  printf '\n%s\n%s\n' \
    '# Global Windows and WSL file finder' \
    'source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/file-finder.zsh"' \
    >> "${zshrc}"
  echo "added file finder to ~/.zshrc"
fi

# Keep deep-research model routing reproducible after Pi package installation.
# Missing dependencies or failed postconditions are fatal: never report a partial setup as success.
PI_WORKFLOW_PATCH="${DOTFILES}/scripts/patch-pi-dynamic-workflows.sh"
PI_WORKFLOW_PACKAGE="${PI_DYNAMIC_WORKFLOWS_DIR:-${HOME}/.pi/agent/npm/node_modules/@quintinshaw/pi-dynamic-workflows}"
if [[ ! -x "${PI_WORKFLOW_PATCH}" ]]; then
  echo "ERROR: Pi workflow patch script is missing or not executable: ${PI_WORKFLOW_PATCH}" >&2
  exit 1
fi
if [[ ! -f "${PI_WORKFLOW_PACKAGE}/package.json" ]]; then
  echo "ERROR: pi-dynamic-workflows is not installed: ${PI_WORKFLOW_PACKAGE}" >&2
  exit 1
fi
PI_DYNAMIC_WORKFLOWS_DIR="${PI_WORKFLOW_PACKAGE}" "${PI_WORKFLOW_PATCH}"
if ! grep -q "openai-codex/gpt-6-astra:medium" "${PI_WORKFLOW_PACKAGE}/src/deep-research.ts" \
  || ! grep -q "openai-codex/gpt-5.6-luna:max" "${PI_WORKFLOW_PACKAGE}/src/deep-research.ts" \
  || ! grep -q "openai-codex/gpt-6-astra:medium" "${PI_WORKFLOW_PACKAGE}/dist/deep-research.js" \
  || ! grep -q "openai-codex/gpt-5.6-luna:max" "${PI_WORKFLOW_PACKAGE}/dist/deep-research.js"; then
  echo "ERROR: Pi workflow routing postcondition failed" >&2
  exit 1
fi

PI_PREFLIGHT="${DOTFILES}/scripts/pi-preflight.sh"
if [[ ! -x "${PI_PREFLIGHT}" ]]; then
  echo "ERROR: Pi preflight script is missing or not executable: ${PI_PREFLIGHT}" >&2
  exit 1
fi
if [[ -n "${JOB_HUNTING_DIR:-}" ]]; then
  PI_WORKFLOW_REGISTER="${DOTFILES}/scripts/register-job-hunting-workflow.sh"
  if [[ ! -x "${PI_WORKFLOW_REGISTER}" ]]; then
    echo "ERROR: job-hunting workflow registration script is missing or not executable: ${PI_WORKFLOW_REGISTER}" >&2
    exit 1
  fi
  "${PI_WORKFLOW_REGISTER}" "${JOB_HUNTING_DIR}"
  "${PI_PREFLIGHT}" "${JOB_HUNTING_DIR}"
else
  "${PI_PREFLIGHT}"
fi

echo "bootstrap done. Open a new shell or 'exec zsh' to pick up env vars."
