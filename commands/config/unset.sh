#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Command: git shadow config unset <KEY> [--project-config|--user-config]
# Purpose: remove a key from a project or user config file.
# -------------------------------------------------------------------

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/config-utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/ui.sh"

SCOPE=""
KEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-config) SCOPE="project"; shift ;;
    --user-config)    SCOPE="user";    shift ;;
    *)
      [[ -z "$KEY" ]] && KEY="$1"
      shift ;;
  esac
done

if [[ -z "$KEY" ]]; then
  printf 'Usage: git shadow config unset <KEY> [--project-config|--user-config]\n' >&2
  exit 1
fi

# Warn but don't block unknown keys (the user may want to clean up a stale entry).
if ! config_is_known_key "$KEY"; then
  ui_warn "Unknown git-shadow config key: $KEY"
fi

# --- Interactive scope selector (if no scope flag given) ---
if [[ -z "$SCOPE" ]]; then
  SCOPE="$(config_prompt_scope "removed from")" || exit 1
fi

FILE="$(config_file_for_scope "$SCOPE")"

if [[ ! -f "$FILE" ]]; then
  ui_info "Config file does not exist, nothing to unset: $FILE"
  exit 0
fi

if ! config_value_in_file "$FILE" "$KEY" >/dev/null 2>&1; then
  ui_info "Key \"$KEY\" is not set in $SCOPE config."
  exit 0
fi

config_unset_in_file "$FILE" "$KEY"
ui_ok "$KEY removed from $SCOPE config ($FILE)"
