#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Command: git shadow config unset <KEY> [--project-config|--user-config]
# Purpose: remove a key from a project or user config file.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)/config-utils.sh"

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
  printf '⚠️  Unknown git-shadow config key: %s\n' "$KEY" >&2
fi

# --- Interactive scope selector (if no scope flag given) ---
if [[ -z "$SCOPE" ]]; then
  SCOPE="$(config_prompt_scope "removed from")" || exit 1
fi

FILE="$(config_file_for_scope "$SCOPE")"

if [[ ! -f "$FILE" ]]; then
  printf 'ℹ️  Config file does not exist, nothing to unset: %s\n' "$FILE"
  exit 0
fi

if ! config_value_in_file "$FILE" "$KEY" >/dev/null 2>&1; then
  printf 'ℹ️  Key "%s" is not set in %s config.\n' "$KEY" "$SCOPE"
  exit 0
fi

config_unset_in_file "$FILE" "$KEY"
printf '✅ %s removed from %s config (%s)\n' "$KEY" "$SCOPE" "$FILE"
