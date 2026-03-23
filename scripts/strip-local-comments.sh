#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Script: strip-local-comments.sh
# Purpose: remove local comment markers from staged files in Git index.
# -------------------------------------------------------------------

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

# Navigate to project and get list of staged files (default to current directory)
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

has_changes=0
while IFS= read -r -d '' file; do
  # Skip deleted files; only process added/copied/modified files
  if [[ ! -f "$file" ]]; then
    continue
  fi

  # Skip files matching LOCAL_COMMENT_EXCLUDE (e.g. *.md, *.json)
  if _is_excluded "$(basename "$file")"; then
    continue
  fi

  # Skip binary files; only text files can contain local comment markers
  if git show ":$file" 2>/dev/null | grep -qI .; then
    :
  else
    continue
  fi

  if ! git show ":$file" 2>/dev/null | grep -qE "$LOCAL_COMMENT_PATTERN"; then
    continue
  fi

  tmp_file="$(mktemp)"

  # Remove lines matching the local comment pattern while preserving other content.
  # grep -v exits 1 when all lines match (file is entirely local comments); || true prevents
  # set -e from aborting.
  git show ":$file" | grep -vE "$LOCAL_COMMENT_PATTERN" > "$tmp_file" || true
  index_info="$(git ls-files -s -- "$file")"
  if [[ -z "$index_info" ]]; then
    echo "Unable to read index info for $file" >&2
    rm -f "$tmp_file"
    exit 1
  fi

  # If the file is now empty and did not exist in HEAD (new file with only local comments),
  # remove it from the index entirely so the caller sees no staged changes.
  if [[ ! -s "$tmp_file" ]] && ! git cat-file -e "HEAD:$file" 2>/dev/null; then
    git rm --cached --quiet -- "$file"
    rm -f "$tmp_file"
    ui_shadow "Local comments removed from index: $file"
    has_changes=1
    continue
  fi

  # Update the Git index with the cleaned file content, preserving mode and path
  mode="$(printf '%s\n' "$index_info" | awk '{print $1}')"
  blob_sha="$(git hash-object -w "$tmp_file")"
  git update-index --cacheinfo "$mode,$blob_sha,$file"

  # Clean up temporary file and mark that we made changes to the index
  rm -f "$tmp_file"
  ui_shadow "Local comments removed from index: $file"
  has_changes=1
done < <(git diff --cached --name-only -z --diff-filter=ACM)

# Inform the user
if [[ "$has_changes" -eq 0 ]]; then
  ui_info "No local comments found in staged files."
else
  ui_ok "Index cleanup complete. Working tree was left untouched."
fi
