#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Command: git shadow config set <KEY>=<VALUE>|<KEY> <VALUE>
#                                [--project-config|--user-config]
# Purpose: write a configuration value to a project or user config file.
# -------------------------------------------------------------------

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/config-utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/ui.sh"

SCOPE=""
KEY=""
VALUE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-config) SCOPE="project"; shift ;;
    --user-config)    SCOPE="user";    shift ;;
    *=*)
      if [[ -z "$KEY" ]]; then
        KEY="${1%%=*}"
        VALUE="${1#*=}"
      fi
      shift ;;
    *)
      if [[ -z "$KEY" ]]; then
        KEY="$1"
      elif [[ -z "$VALUE" ]]; then
        VALUE="$1"
      fi
      shift ;;
  esac
done

# --- Interactive key selector (if no key given and stdin is a TTY) ---
if [[ -z "$KEY" ]]; then
  if [[ ! -t 0 ]]; then
    printf 'Usage: git shadow config set <KEY>=<VALUE> [--project-config|--user-config]\n' >&2
    exit 1
  fi
  printf 'Select the configuration key to set:\n' >&2
  declare -a _keys_list=()
  local_i=1
  while IFS= read -r k; do
    desc="$(config_description "$k" || true)"
    printf '  %2d) %-35s %s\n' "$local_i" "$k" "$desc" >&2
    _keys_list+=("$k")
    ((local_i++))
  done < <(config_known_keys)
  printf 'Enter number: ' >&2
  read -r _choice
  KEY="${_keys_list[$((_choice - 1))]}"
fi

# --- Interactive value prompt (if no value given and stdin is a TTY) ---
if [[ -z "$VALUE" ]]; then
  if [[ ! -t 0 ]]; then
    printf 'Usage: git shadow config set <KEY>=<VALUE> [--project-config|--user-config]\n' >&2
    exit 1
  fi
  current_default="$(config_default_value "$KEY" || true)"
  printf 'Enter value for %s [default: %s]: ' "$KEY" "$current_default" >&2
  read -r VALUE
  [[ -z "$VALUE" ]] && VALUE="$current_default"
fi

# Warn but don't block unknown keys (forward-compat).
if ! config_is_known_key "$KEY"; then
  ui_warn "Unknown git-shadow config key: $KEY (writing anyway)"
fi

# --- Interactive scope selector (if no scope flag given) ---
if [[ -z "$SCOPE" ]]; then
  SCOPE="$(config_prompt_scope "written")" || exit 1
fi

FILE="$(config_file_for_scope "$SCOPE")"
config_set_in_file "$FILE" "$KEY" "$VALUE"
ui_ok "$KEY=\"$VALUE\" written to $SCOPE config ($FILE)"
