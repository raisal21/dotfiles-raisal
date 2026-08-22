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

echo "bootstrap done. Open a new shell or 'exec zsh' to pick up env vars."
