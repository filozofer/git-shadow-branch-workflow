#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

load_env() {
  if [[ -f "$TOOLKIT_ROOT/.env.example" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$TOOLKIT_ROOT/.env.example"
    set +a
  fi

  if [[ -f "$TOOLKIT_ROOT/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$TOOLKIT_ROOT/.env"
    set +a
  fi

  : "${WORKSPACE_DIR:=../}"
  : "${PUBLIC_BASE_BRANCH:=develop}"
  : "${LOCAL_SUFFIX:=@local}"
  : "${LOCAL_COMMENT_PATTERN:=^[[:space:]]*//[[:space:]]*@local([[:space:]]|$)}"
  : "${SYNC_MERGE_MESSAGE_TEMPLATE:=[SYNC] merge '%s' into '%s'}"
  : "${FEATURE_MERGE_MESSAGE_TEMPLATE:=[FEATURE] merge '%s' into '%s'}"
  : "${HOOK_CHECK_MARKER:=# local-comments-workflow}"
}
