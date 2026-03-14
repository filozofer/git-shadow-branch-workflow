#!/usr/bin/env bash
set -euo pipefail

# Recommended Git alias:
# git config --global alias.check-local-comments '!f() { /ABSOLUTE/PATH/TO/git-local-comments-workflow/scripts/check-local-comments.sh "$@"; }; f'

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-dir>" >&2
  exit 1
fi

enter_project "$1"

staged_files="$(git diff --cached --name-only --diff-filter=ACM)"

if [[ -z "$staged_files" ]]; then
  exit 0
fi

has_local_comments=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  if git show ":$file" 2>/dev/null | grep -nE "$LOCAL_COMMENT_PATTERN" >/dev/null 2>&1; then
    if [[ "$has_local_comments" -eq 0 ]]; then
      echo "❌ Commit blocked: local comments are still present in staged files."
      echo
    fi

    has_local_comments=1
    echo "File: $file"
    git show ":$file" | grep -nE "$LOCAL_COMMENT_PATTERN" || true
    echo
  fi
done <<< "$staged_files"

if [[ "$has_local_comments" -eq 1 ]]; then
  echo "Run this first:"
  echo "$TOOLKIT_ROOT/scripts/strip-local-comments.sh $PWD"
  exit 1
fi
