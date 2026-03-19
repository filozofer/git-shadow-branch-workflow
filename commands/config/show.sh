#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Command: git shadow config show [--json]
# Purpose: display the effective merged configuration with source tier.
# -------------------------------------------------------------------

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/config-utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/env.sh"
load_env

JSON=false
for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON=true
done

if $JSON; then
  printf '{\n'
  first=true
  while IFS= read -r key; do
    value="${!key:-}"
    source_tier="$(config_source_of "$key")"
    $first || printf ',\n'
    first=false
    printf '  "%s": {"value": "%s", "source": "%s"}' \
      "$(_json_escape "$key")" \
      "$(_json_escape "$value")" \
      "$(_json_escape "$source_tier")"
  done < <(config_known_keys)
  printf '\n}\n'
else
  while IFS= read -r key; do
    value="${!key:-}"
    source_tier="$(config_source_of "$key")"
    printf '%-35s %-45s (source: %s)\n' "$key" "$value" "$source_tier"
  done < <(config_known_keys)
fi
