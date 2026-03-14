#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-dir> [-m \"message\"]" >&2
  exit 1
fi

PROJECT_ARG="$1"
shift
COMMIT_MESSAGE=""

while getopts "m:" opt; do
  case $opt in
    m) COMMIT_MESSAGE="$OPTARG" ;;
    *)
      echo "Usage: $0 <project-dir> [-m \"message\"]" >&2
      exit 1
      ;;
  esac
done

enter_project "$PROJECT_ARG"

git add .

if git diff --cached --quiet; then
  echo "❌ No staged changes." >&2
  exit 1
fi

"$TOOLKIT_ROOT/scripts/strip-local-comments.sh" "$PWD"

if git diff --cached --quiet; then
  echo "❌ After removing local comments, nothing remains to commit." >&2
  exit 1
fi

if [[ -n "$COMMIT_MESSAGE" ]]; then
  git commit -m "$COMMIT_MESSAGE"
else
  git commit
fi

last_commit_message="$(git log -1 --pretty=%s)"

git add .

if git diff --cached --quiet; then
  echo "ℹ️ No local comments to save in a separate commit."
  exit 0
fi

git commit -m "[COMMENTS] $last_commit_message" --no-verify
