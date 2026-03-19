#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Command: git shadow config list [--json]
# Purpose: list all known git-shadow configuration keys.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)/config-utils.sh"

JSON=false
for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON=true
done

if $JSON; then
  printf '[\n'
  first=true
  while IFS= read -r key; do
    default="$(config_default_value "$key" || true)"
    desc="$(config_description "$key" || true)"
    $first || printf ',\n'
    first=false
    printf '  {"key":"%s","default":"%s","description":"%s"}' \
      "$(_json_escape "$key")" \
      "$(_json_escape "$default")" \
      "$(_json_escape "$desc")"
  done < <(config_known_keys)
  printf '\n]\n'
else
  while IFS= read -r key; do
    default="$(config_default_value "$key" || true)"
    desc="$(config_description "$key" || true)"
    printf '%-35s %-20s %s\n' "$key" "$default" "$desc"
  done < <(config_known_keys)
fi
