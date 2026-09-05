# Global Windows and WSL file finder. This file must be sourced so `ff` can cd.
ff() {
  emulate -L zsh
  setopt localoptions pipefail

  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local provider="${config_home}/scripts/file-finder-provider"

  if [[ ! -x "$provider" ]]; then
    print -r -u2 -- "ff: provider is missing or not executable: $provider"
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'ff: fzf is not installed'
    return 1
  fi

  local source
  if command -v es.exe >/dev/null 2>&1; then
    source=windows
  elif command -v plocate >/dev/null 2>&1; then
    source=linux
  else
    print -u2 'ff: install es.exe (Windows) or plocate (WSL) first'
    return 1
  fi

  local state
  state="$(mktemp "${TMPDIR:-/tmp}/ff.XXXXXXXX")" || return 1
  "$provider" set-mode "$state" "$source" || {
    rm -f -- "$state"
    return 1
  }

  local provider_q="${(q)provider}"
  local state_q="${(q)state}"
  local query_command="${provider_q} query ${state_q} {q}"
  local initial_prompt='1. Everything> '
  [[ "$source" == linux ]] && initial_prompt='1. WSL> '

  local -a finder
  if [[ -n "${TMUX:-}" ]] && command -v fzf-tmux >/dev/null 2>&1; then
    finder=(fzf-tmux -p 80%,80% --)
  else
    finder=(fzf --height=80%)
  fi

  local selected active_source
  selected="$("${finder[@]}" \
    --disabled \
    --track \
    --scheme=path \
    --layout=reverse \
    --border=sharp \
    --margin=1 \
    --padding=1 \
    --prompt="$initial_prompt" \
    --header='Ctrl-W: Windows  Ctrl-L: WSL  Alt-Enter: fuzzy current results' \
    --color='bg:-1,bg+:-1,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,border:#585b70' \
    --bind="start:reload(${query_command})" \
    --bind="change:reload(sleep 0.1; ${query_command})" \
    --bind="ctrl-w:execute-silent(${provider_q} set-mode ${state_q} windows)+rebind(change)+disable-search+change-prompt(1. Everything> )+reload(${query_command})" \
    --bind="ctrl-l:execute-silent(${provider_q} set-mode ${state_q} linux)+rebind(change)+disable-search+change-prompt(1. WSL> )+reload(${query_command})" \
    --bind='alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query' \
    < /dev/null)"
  local finder_status=$?

  active_source="$(<"$state")"
  rm -f -- "$state"

  (( finder_status == 0 )) || return "$finder_status"
  [[ -n "$selected" ]] || return 0

  local target="$selected"
  if [[ "$active_source" == windows ]]; then
    if ! target="$(wslpath -u "$selected" 2>/dev/null)"; then
      if command -v wslview >/dev/null 2>&1; then
        wslview "$selected"
        return $?
      fi
      print -r -u2 -- "ff: cannot convert Windows path: $selected"
      return 1
    fi
  fi

  if [[ -d "$target" ]]; then
    builtin cd -- "$target"
  elif [[ -e "$target" ]]; then
    local mime
    mime="$(file -L --brief --mime-type -- "$target" 2>/dev/null)"

    case "$mime" in
      text/*|application/json|application/*+json|application/xml|application/*+xml|application/javascript|application/x-shellscript|inode/x-empty)
        if command -v v >/dev/null 2>&1; then
          v -- "$target"
        else
          nvim -- "$target"
        fi
        ;;
      *)
        if command -v wslview >/dev/null 2>&1; then
          wslview "$target"
        elif command -v xdg-open >/dev/null 2>&1; then
          command xdg-open "$target"
        else
          print -u2 'ff: install wslu or xdg-utils to open non-text files'
          return 1
        fi
        ;;
    esac
  else
    print -r -u2 -- "ff: selection no longer exists: $target"
    return 1
  fi
}
