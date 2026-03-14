#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: git publish <project-dir> [--commit] [-m \"MESSAGE\"]" >&2
  exit 1
fi

PROJECT_ARG="$1"
shift
COMMIT_FIRST=0
COMMIT_MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      COMMIT_FIRST=1
      shift
      ;;
    -m)
      if [[ $# -lt 2 ]]; then
        echo "❌ The -m option requires a message." >&2
        exit 1
      fi
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1" >&2
      echo "Usage: git publish <project-dir> [--commit] [-m \"MESSAGE\"]" >&2
      exit 1
      ;;
  esac
done

enter_project "$PROJECT_ARG"
CURRENT_BRANCH="$(current_branch)"

if [[ -z "$CURRENT_BRANCH" ]]; then
  echo "❌ Unable to determine current branch." >&2
  exit 1
fi

if [[ ! "$CURRENT_BRANCH" =~ ${LOCAL_SUFFIX}$ ]]; then
  echo "❌ git publish must be run from a branch ending with '$LOCAL_SUFFIX'." >&2
  echo "   Current branch: $CURRENT_BRANCH" >&2
  exit 1
fi

TARGET_BRANCH="${CURRENT_BRANCH%$LOCAL_SUFFIX}"
SOURCE_BRANCH="$CURRENT_BRANCH"

if [[ "$COMMIT_FIRST" -eq 1 ]]; then
  if [[ -n "$COMMIT_MESSAGE" ]]; then
    "$TOOLKIT_ROOT/scripts/commit-with-separate-local-comments.sh" "$PWD" -m "$COMMIT_MESSAGE"
  else
    "$TOOLKIT_ROOT/scripts/commit-with-separate-local-comments.sh" "$PWD"
  fi
fi

ensure_clean_repo

if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  echo "❌ Target branch does not exist: $TARGET_BRANCH" >&2
  exit 1
fi

echo "🔀 Checkout target branch: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH"

commits_to_pick=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  status="${line:0:1}"
  sha="${line:2}"
  subject="$(git log -1 --pretty=%s "$sha")"

  if [[ "$status" != "+" ]]; then
    echo "⏭️  Ignored (patch already present): $sha  $subject"
    continue
  fi

  if [[ "$subject" =~ ^\[COMMENTS?\] ]]; then
    echo "⏭️  Ignored (local comments): $sha  $subject"
    continue
  fi

  commits_to_pick+=("$sha")
done < <(git cherry "$TARGET_BRANCH" "$SOURCE_BRANCH")

if [[ "${#commits_to_pick[@]}" -eq 0 ]]; then
  echo "ℹ️ No publishable commits to cherry-pick from $SOURCE_BRANCH to $TARGET_BRANCH."
  exit 0
fi

echo "📦 Commits to cherry-pick:"
for sha in "${commits_to_pick[@]}"; do
  git log -1 --pretty=' - %h %s' "$sha"
done

for sha in "${commits_to_pick[@]}"; do
  echo "🍒 Cherry-picking $sha"

  if git cherry-pick "$sha"; then
    continue
  fi

  cherry_pick_head_file="$(git rev-parse --git-path CHERRY_PICK_HEAD)"
  if [[ -f "$cherry_pick_head_file" ]] && git diff --quiet && git diff --cached --quiet; then
    echo "⏭️  Empty cherry-pick detected, skipping: $sha"
    git cherry-pick --skip
    continue
  fi

  echo "❌ Cherry-pick conflict on commit: $sha" >&2
  echo "Resolve it, then run 'git cherry-pick --continue' or 'git cherry-pick --abort'." >&2
  exit 1
done

echo "✅ Publish completed on branch: $TARGET_BRANCH"
