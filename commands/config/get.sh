#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Command: git shadow config get <KEY> [--json]
# Purpose: return the effective value and source tier for a single key.
# -------------------------------------------------------------------

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/config-utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/env.sh"
load_env

JSON=false
KEY=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    *)      [[ -z "$KEY" ]] && KEY="$arg" ;;
  esac
done

if [[ -z "$KEY" ]]; then
  printf 'Usage: git shadow config get <KEY> [--json]\n' >&2
  exit 1
fi

if ! config_is_known_key "$KEY"; then
  printf '❌ Unknown configuration key: %s\n' "$KEY" >&2
  exit 1
fi

value="${!KEY:-}"
source_tier="$(config_source_of "$KEY")"
desc="$(config_description "$KEY" || true)"

if $JSON; then
  printf '{"key":"%s","value":"%s","source":"%s","description":"%s"}\n' \
    "$(_json_escape "$KEY")" \
    "$(_json_escape "$value")" \
    "$(_json_escape "$source_tier")" \
    "$(_json_escape "$desc")"
else
  printf '%s=%s   (source: %s)\n' "$KEY" "$value" "$source_tier"
fi
