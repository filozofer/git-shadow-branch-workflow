#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-dir>" >&2
  exit 1
fi

enter_project "$1"

has_changes=0

while IFS= read -r -d '' file; do
  # Skip deleted files; only process added/copied/modified files
  if [[ ! -f "$file" ]]; then
    continue
  fi

  # Skip binary files completely; only treat text files.
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
  git show ":$file" | grep -vE "$LOCAL_COMMENT_PATTERN" > "$tmp_file"

  index_info="$(git ls-files -s -- "$file")"
  if [[ -z "$index_info" ]]; then
    echo "Unable to read index info for $file" >&2
    rm -f "$tmp_file"
    exit 1
  fi

  mode="$(printf '%s\n' "$index_info" | awk '{print $1}')"
  blob_sha="$(git hash-object -w "$tmp_file")"
  git update-index --cacheinfo "$mode,$blob_sha,$file"

  rm -f "$tmp_file"
  echo "Local comments removed from index: $file"
  has_changes=1
done < <(git diff --cached --name-only -z --diff-filter=ACM)

if [[ "$has_changes" -eq 0 ]]; then
  echo "No local comments found in staged files."
else
  echo "Index cleanup complete. Working tree was left untouched."
fi
