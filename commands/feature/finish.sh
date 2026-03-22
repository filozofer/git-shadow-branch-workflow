#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Script: feature/finish.sh
# Purpose: finalize a feature by validating public integration,
# updating local base branches, merging local feature work back
# into the local base, and optionally deleting feature branches.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" && pwd)/common.sh"

# Finish-feature operates on current repository only.
PROJECT_ARG='.'
DELETE_BRANCHES=1
PULL_BASES=1
FORCE_DELETE=0

# Parse optional flags for finish-feature behavior
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-branches)
      DELETE_BRANCHES=0
      shift
      ;;
    --no-pull)
      PULL_BASES=0
      shift
      ;;
    --force)
      FORCE_DELETE=1
      shift
      ;;
    *)
      ui_error "Unknown argument: $1"
      echo "Usage: git shadow feature finish [--keep-branches] [--no-pull] [--force]" >&2
      exit 1
      ;;
  esac
done

# Enter project and ensure repo is in clean state
enter_project "$PROJECT_ARG"
ensure_clean_repo
current_branch_name="$(current_branch)"
feature_public_branch="$(public_branch_from_any "$current_branch_name")"
feature_local_branch="$(local_branch_from_any "$current_branch_name")"
public_base="$PUBLIC_BASE_BRANCH"
local_base="${PUBLIC_BASE_BRANCH}${LOCAL_SUFFIX}"
if [[ "$feature_public_branch" == "$public_base" || "$feature_local_branch" == "$local_base" ]]; then
  ui_error "This command must be run from a feature branch, not from $public_base or $local_base."
  exit 1
fi

# Ensure all expected branches exist locally before proceeding
for branch in "$feature_public_branch" "$feature_local_branch" "$public_base" "$local_base"; do
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    ui_error "Branch does not exist locally: $branch"
    exit 1
  fi
done

# Display summary of detected branches and bases
ui_shadow "Finalizing feature branches"
ui_git    "   Public branch : $feature_public_branch"
ui_shadow "   Local branch  : $feature_local_branch"
ui_git    "   Public base   : $public_base"
ui_shadow "   Local base    : $local_base"
echo

# Sync public base
ui_git "Checkout $public_base"
git checkout "$public_base"
if [[ "$PULL_BASES" -eq 1 ]]; then
  ui_git "Pulling latest changes for $public_base"
  git pull
fi
public_branch_merged=0
if git merge-base --is-ancestor "$feature_public_branch" "$public_base"; then
  public_branch_merged=1
fi

# Warn if the public branch does not appear to be merged into the public base
if [[ "$public_branch_merged" -eq 1 ]]; then
  ui_ok "'$feature_public_branch' is already merged into '$public_base'."
else
  ui_warn "'$feature_public_branch' does NOT appear to be merged into '$public_base'."
  if [[ "$DELETE_BRANCHES" -eq 1 && "$FORCE_DELETE" -eq 0 ]]; then
    ui_error "Branch deletion aborted to avoid losing work."
    ui_step "Run with --force if you really want to continue."
    exit 1
  fi
fi

# Sync local base with public base to prepare for final merge
ui_shadow "Checkout $local_base"
git checkout "$local_base"
if [[ "$PULL_BASES" -eq 1 ]]; then
  ui_shadow "Pulling latest changes for $local_base"
  if ! git pull; then
    ui_warn "Failed to pull '$local_base'. Continuing with local state."
  fi
fi

# Merge public base into local base, then feature local branch into local base
# shellcheck disable=SC2059
sync_message="$(printf "$SYNC_MERGE_MESSAGE_TEMPLATE" "$public_base" "$local_base")"
# shellcheck disable=SC2059
feature_message="$(printf "$FEATURE_MERGE_MESSAGE_TEMPLATE" "$feature_local_branch" "$local_base")"
ui_shadow "Merging '$public_base' into '$local_base'"
git merge --no-edit -m "$sync_message" "$public_base"
ui_shadow "Merging '$feature_local_branch' into '$local_base'"
git merge --no-edit -m "$feature_message" "$feature_local_branch"

# Handle branch cleanup based on user preferences
if [[ "$DELETE_BRANCHES" -eq 1 ]]; then
  ui_info "Cleaning up feature branches"

  if [[ "$public_branch_merged" -eq 1 ]]; then
    git branch -d "$feature_public_branch"
  else
    ui_warn "Forcing deletion of '$feature_public_branch' (--force used)"
    git branch -D "$feature_public_branch"
  fi

  if git merge-base --is-ancestor "$feature_local_branch" "$local_base"; then
    git branch -d "$feature_local_branch"
  else
    if [[ "$FORCE_DELETE" -eq 1 ]]; then
      ui_warn "Forcing deletion of '$feature_local_branch'"
      git branch -D "$feature_local_branch"
    else
      ui_warn "'$feature_local_branch' was not fully merged into '$local_base'."
      ui_step "Local branch kept."
    fi
  fi
else
  ui_info "Feature branches preserved (--keep-branches)"
fi

echo
ui_ok     "Feature finished successfully."
ui_shadow "Current branch: $local_base"
