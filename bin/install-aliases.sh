#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git config --global alias.new-feature "!f() { '$TOOLKIT_ROOT/scripts/git-new-feature.sh' \"\$@\"; }; f"
git config --global alias.publish "!f() { '$TOOLKIT_ROOT/scripts/git-publish.sh' \"\$@\"; }; f"
git config --global alias.finish-feature "!f() { '$TOOLKIT_ROOT/scripts/git-finish-feature.sh' \"\$@\"; }; f"

echo "✅ Git aliases installed: new-feature, publish, finish-feature"
