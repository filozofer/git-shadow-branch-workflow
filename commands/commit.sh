#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Script: commit.sh
# Purpose: commit cleaned code, then commit local comments separately.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

# Commit in current repository (no project path argument supported)
COMMIT_MESSAGE=""

# Parse optional `-m` commit message
while getopts "m:" opt; do
  case $opt in
    m) COMMIT_MESSAGE="$OPTARG" ;;
    *)
      echo "Usage: $0 [-m \"message\"]" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))
if [[ $# -gt 0 ]]; then
  ui_error "Unknown argument(s): $*"
  echo "Usage: $0 [-m \"message\"]" >&2
  exit 1
fi

# Enter current project directory
enter_project "."

# Verify there is something to commit
if git diff --cached --quiet; then
  ui_error "No staged changes."
  exit 1
fi

# Remove local comments from index while keeping working tree unmodified
"$TOOLKIT_ROOT/scripts/strip-local-comments.sh"

# If no code remains after stripping comments, abort commit
if git diff --cached --quiet; then
  ui_error "After removing local comments, nothing remains to commit."
  ui_step "You can commit your local comments with:"
  ui_step "git commit -m \"$SHADOW_COMMIT_PREFIX title\" --no-verify"
  exit 1
fi

# Create main commit (clean code)
if [[ -n "$COMMIT_MESSAGE" ]]; then
  git commit -m "$COMMIT_MESSAGE"
else
  git commit
fi

# Remember last non-comment commit message for comments commit reference
last_commit_message="$(git log -1 --pretty=%s)"

# Stage changes again to capture local comments that remain
git add .

if git diff --cached --quiet; then
  ui_info "No local comments to save in a separate commit."
  exit 0
fi

# Commit local comments in a separate shadow commit
ui_shadow "Local comments found — saving shadow commit"
git commit -m "$SHADOW_COMMIT_PREFIX $last_commit_message" --no-verify
