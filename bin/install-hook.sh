#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$TOOLKIT_ROOT/lib/common.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-dir>" >&2
  exit 1
fi

PROJECT_ARG="$1"
enter_project "$PROJECT_ARG"
project_path="$PWD"
hook_file="$(detect_hook_file pre-commit)"
mkdir -p "$(dirname "$hook_file")"

hook_script="\"$TOOLKIT_ROOT/scripts/check-local-comments.sh\" \"$project_path\""

if [[ -f "$hook_file" ]] && grep -Fq "$HOOK_CHECK_MARKER" "$hook_file"; then
  echo "ℹ️ Hook already installed in: $hook_file"
  exit 0
fi

if [[ -f "$hook_file" ]]; then
  printf '\n%s\n%s\n' "$HOOK_CHECK_MARKER" "$hook_script" >> "$hook_file"
else
  cat > "$hook_file" <<EOF2
#!/usr/bin/env sh
$HOOK_CHECK_MARKER
$hook_script
EOF2
  chmod +x "$hook_file"
fi

echo "✅ Hook installed in: $hook_file"