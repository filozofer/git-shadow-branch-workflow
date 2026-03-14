#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
load_env

abs_path() {
  local path="$1"

  # If already absolute (Unix or Windows drive path), return as-is.
  if [[ "$path" = /* || "$path" =~ ^[A-Za-z]:[\\/] ]]; then
    echo "$path"
    return
  fi

  # Prefer realpath when available.
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
    return
  fi

  # Prefer readlink -f on platforms that support it (Linux, Git Bash).
  if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then
    readlink -f "$path"
    return
  fi

  # Fallback: use POSIX shell only.
  local cwd
  cwd="$(pwd)"
  local dir
  dir="$(dirname "$path")"
  local base
  base="$(basename "$path")"

  if [[ -d "$dir" ]]; then
    cd "$dir"
    printf '%s/%s\n' "$(pwd)" "$base"
    cd "$cwd"
    return
  fi

  # If directory does not exist, resolve parent and append basename.
  cd "$dir" >/dev/null 2>&1 || return 1
  printf '%s/%s\n' "$(pwd)" "$base"
  cd "$cwd"
}

resolve_workspace_dir() {
  if [[ "$WORKSPACE_DIR" = /* ]]; then
    printf '%s\n' "$WORKSPACE_DIR"
  else
    abs_path "$TOOLKIT_ROOT/$WORKSPACE_DIR"
  fi
}

resolve_project_path() {
  local project_arg="$1"
  local workspace
  workspace="$(resolve_workspace_dir)"

  if [[ "$project_arg" = /* ]]; then
    printf '%s\n' "$(abs_path "$project_arg")"
  else
    printf '%s\n' "$(abs_path "$workspace/$project_arg")"
  fi
}

enter_project() {
  local project_arg="$1"
  local project_path
  project_path="$(resolve_project_path "$project_arg")"

  if [[ ! -d "$project_path" ]]; then
    echo "❌ Project directory not found: $project_path" >&2
    exit 1
  fi

  cd "$project_path"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Not a Git repository: $project_path" >&2
    exit 1
  fi
}

current_branch() {
  git branch --show-current
}

public_branch_from_any() {
  local branch="$1"
  if [[ "$branch" =~ ${LOCAL_SUFFIX}$ ]]; then
    printf '%s\n' "${branch%$LOCAL_SUFFIX}"
  else
    printf '%s\n' "$branch"
  fi
}

local_branch_from_any() {
  local branch="$1"
  if [[ "$branch" =~ ${LOCAL_SUFFIX}$ ]]; then
    printf '%s\n' "$branch"
  else
    printf '%s\n' "${branch}${LOCAL_SUFFIX}"
  fi
}

ensure_clean_repo() {
  local cherry_pick_head_file merge_head_file rebase_merge_dir rebase_apply_dir
  cherry_pick_head_file="$(git rev-parse --git-path CHERRY_PICK_HEAD)"
  merge_head_file="$(git rev-parse --git-path MERGE_HEAD)"
  rebase_merge_dir="$(git rev-parse --git-path rebase-merge)"
  rebase_apply_dir="$(git rev-parse --git-path rebase-apply)"

  if [[ -f "$cherry_pick_head_file" ]]; then
    echo "❌ A cherry-pick is still in progress." >&2
    exit 1
  fi

  if [[ -f "$merge_head_file" ]]; then
    echo "❌ A merge is still in progress." >&2
    exit 1
  fi

  if [[ -d "$rebase_merge_dir" || -d "$rebase_apply_dir" ]]; then
    echo "❌ A rebase is still in progress." >&2
    exit 1
  fi

  if ! git diff --quiet; then
    echo "❌ Working tree contains uncommitted changes." >&2
    git diff --name-only >&2
    exit 1
  fi

  if ! git diff --cached --quiet; then
    echo "❌ Index still contains staged changes." >&2
    git diff --cached --name-only >&2
    exit 1
  fi
}

detect_hook_file() {
  local hook_name="${1:-pre-commit}"
  local hooks_path

  hooks_path="$(git config --get core.hooksPath || true)"
  hooks_path="${hooks_path%/}"

  if [[ -z "$hooks_path" ]]; then
    printf '%s\n' ".git/hooks/$hook_name"
    return
  fi

  # Husky uses .husky/_ as internal hooksPath, but project hooks live in .husky/
  if [[ "$hooks_path" == ".husky/_" ]]; then
    printf '%s\n' ".husky/$hook_name"
    return
  fi

  printf '%s\n' "$hooks_path/$hook_name"
}
