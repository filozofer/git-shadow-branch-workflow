#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Script: check-local-comments.sh
# Purpose: reject commits with local-only comments in staged files.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

# Navigate to project (default to current directory for hook usage)
enter_project "${1:-.}"

# Return 0 if the file matches any glob in LOCAL_COMMENT_EXCLUDE, 1 otherwise.
_is_excluded() {
  local file="$1" pattern
  set -f  # disable glob expansion so *.md stays a pattern, not a file list
  for pattern in $LOCAL_COMMENT_EXCLUDE; do
    # shellcheck disable=SC2254
    case "$file" in
      $pattern) set +f; return 0 ;;
    esac
  done
  set +f
  return 1
}

# Get list of staged files and check for local comments
staged_files="$(git diff --cached --name-only --diff-filter=ACM)"
if [[ -z "$staged_files" ]]; then
  exit 0
fi
has_local_comments=0
while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Skip files matching LOCAL_COMMENT_EXCLUDE (e.g. *.md, *.json)
  if _is_excluded "$(basename "$file")"; then
    continue
  fi

  # Search staged file content for lines matching LOCAL_COMMENT_PATTERN
  if git show ":$file" 2>/dev/null | grep -nE "$LOCAL_COMMENT_PATTERN" >/dev/null 2>&1; then
    if [[ "$has_local_comments" -eq 0 ]]; then
      ui_error "Commit blocked: local comments are still present in staged files."
      echo
    fi
    has_local_comments=1
    ui_shadow "File: $file"
    git show ":$file" | grep -nE "$LOCAL_COMMENT_PATTERN" || true
    echo
  fi
done <<< "$staged_files"

# Inform the user if local comments were found and reject the commit
if [[ "$has_local_comments" -eq 1 ]]; then
  ui_step "Run this first: git shadow commit"
  exit 1
fi
