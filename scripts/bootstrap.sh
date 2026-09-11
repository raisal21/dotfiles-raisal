#!/usr/bin/env bash
# Bootstrap dotfiles on a fresh machine.
# Assumes this repo is cloned to ~/dotfiles.

set -euo pipefail

DOTFILES="${HOME}/dotfiles"
CONFIG="${HOME}/.config"

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

# Keep the global Pi Advisor profile versioned with the dotfiles.
PI_AGENT="${HOME}/.pi/agent"
PI_ADVISOR_SOURCE="${DOTFILES}/pi/advisor.json"
PI_ADVISOR_TARGET="${PI_AGENT}/advisor.json"

if [[ -f "${PI_ADVISOR_SOURCE}" ]]; then
  mkdir -p "${PI_AGENT}"
  if [[ -L "${PI_ADVISOR_TARGET}" && "$(readlink "${PI_ADVISOR_TARGET}")" == "${PI_ADVISOR_SOURCE}" ]]; then
    echo "linked: ${PI_ADVISOR_TARGET} -> ${PI_ADVISOR_SOURCE}"
  else
    if [[ -e "${PI_ADVISOR_TARGET}" || -L "${PI_ADVISOR_TARGET}" ]]; then
      advisor_backup="${PI_ADVISOR_TARGET}.bak.$(date +%Y%m%d-%H%M%S)"
      mv "${PI_ADVISOR_TARGET}" "${advisor_backup}"
      echo "backed up existing Pi Advisor profile to ${advisor_backup}"
    fi
    ln -s "${PI_ADVISOR_SOURCE}" "${PI_ADVISOR_TARGET}"
    echo "linked: ${PI_ADVISOR_TARGET} -> ${PI_ADVISOR_SOURCE}"
  fi
fi

# Link the Windows Kanata config back to the repo when the target directory exists.
KANATA_SOURCE="${DOTFILES}/kanata/kanata.kbd"
KANATA_TARGET="${KANATA_CONFIG_PATH:-/mnt/c/Users/PC-Windows/Documents/Kanata/kanata.kbd}"
KANATA_DIR="$(dirname "${KANATA_TARGET}")"

if [[ -d "${KANATA_DIR}" ]]; then
  if [[ -e "${KANATA_TARGET}" || -L "${KANATA_TARGET}" ]]; then
    if [[ -L "${KANATA_TARGET}" && "$(readlink "${KANATA_TARGET}")" == "${KANATA_SOURCE}" ]]; then
      echo "linked: ${KANATA_TARGET} -> ${KANATA_SOURCE}"
    else
      kanata_backup="${KANATA_TARGET}.bak.$(date +%Y%m%d-%H%M%S)"
      mv "${KANATA_TARGET}" "${kanata_backup}"
      ln -s "${KANATA_SOURCE}" "${KANATA_TARGET}"
      echo "backed up existing Kanata config to ${kanata_backup}"
      echo "linked: ${KANATA_TARGET} -> ${KANATA_SOURCE}"
    fi
  else
    ln -s "${KANATA_SOURCE}" "${KANATA_TARGET}"
    echo "linked: ${KANATA_TARGET} -> ${KANATA_SOURCE}"
  fi
else
  echo "skipped Kanata link: ${KANATA_DIR} not found"
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
# Run this last so an unsupported upstream version cannot skip unrelated links.
PI_WORKFLOW_PATCH="${DOTFILES}/scripts/patch-pi-dynamic-workflows.sh"
PI_WORKFLOW_PACKAGE="${PI_DYNAMIC_WORKFLOWS_DIR:-${HOME}/.pi/agent/npm/node_modules/@quintinshaw/pi-dynamic-workflows}"
if [[ -x "${PI_WORKFLOW_PATCH}" && -f "${PI_WORKFLOW_PACKAGE}/package.json" ]]; then
  PI_DYNAMIC_WORKFLOWS_DIR="${PI_WORKFLOW_PACKAGE}" "${PI_WORKFLOW_PATCH}"
elif [[ -x "${PI_WORKFLOW_PATCH}" ]]; then
  echo "skipped Pi workflow patch: ${PI_WORKFLOW_PACKAGE} is not installed yet"
fi

echo "bootstrap done. Open a new shell or 'exec zsh' to pick up env vars."
