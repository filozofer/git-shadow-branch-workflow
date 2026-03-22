#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Script: promote.sh
# Purpose: create a promotion commit to publish a shadow-only file
#          to the public branch via git shadow feature publish.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

if [[ $# -ne 1 ]]; then
  ui_error "Usage: git shadow promote <file>"
  exit 1
fi
FILE="$1"

# Must be on a shadow branch
enter_project "."
CURRENT_BRANCH="$(current_branch)"
if [[ -z "$CURRENT_BRANCH" ]]; then
  ui_error "Unable to determine current branch."
  exit 1
fi
if [[ ! "$CURRENT_BRANCH" =~ ${LOCAL_SUFFIX}$ ]]; then
  ui_error "git shadow promote must be run from a branch ending with '$LOCAL_SUFFIX'."
  ui_step "Current branch: $CURRENT_BRANCH"
  exit 1
fi
TARGET_BRANCH="${CURRENT_BRANCH%"$LOCAL_SUFFIX"}"

# File must exist in the shadow branch (committed)
if ! git cat-file -e "HEAD:$FILE" 2>/dev/null; then
  ui_error "File not found in shadow branch: $FILE"
  ui_step "Make sure the file is committed on '$CURRENT_BRANCH' before promoting."
  exit 1
fi

# File must NOT already exist on the public branch
if git cat-file -e "${TARGET_BRANCH}:${FILE}" 2>/dev/null; then
  ui_error "File already exists on public branch '$TARGET_BRANCH': $FILE"
  ui_step "Use a regular commit to modify existing files on the public branch."
  exit 1
fi

# Retrieve the blob SHA of the file at HEAD on the shadow branch
BLOB_SHA="$(git rev-parse "HEAD:$FILE")"

# Create the promotion commit (--allow-empty since no files are staged)
COMMIT_MSG="shadow: promote $FILE

path=$FILE
blob=$BLOB_SHA"

ui_shadow "Creating promotion commit for: $FILE"
ui_step "blob: $BLOB_SHA"
git commit --allow-empty -m "$COMMIT_MSG" --no-verify
ui_ok "Promotion commit created — run 'git shadow feature publish' to apply."
