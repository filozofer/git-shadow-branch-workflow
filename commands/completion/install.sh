#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Script: completion/install.sh
# Purpose: install git-shadow shell completion for bash or zsh.
# -------------------------------------------------------------------

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

COMPLETION_MARKER="# git-shadow completion"

# ---------------------------------------------------------------------------
# Shell detection
# ---------------------------------------------------------------------------

SHELL_NAME="$(basename "${SHELL:-}")"

case "$SHELL_NAME" in
  bash)
    COMPLETION_SCRIPT="$TOOLKIT_ROOT/completions/git-shadow.bash"
    SHELL_RC="${HOME}/.bashrc"
    ;;
  zsh)
    COMPLETION_SCRIPT="$TOOLKIT_ROOT/completions/git-shadow.zsh"
    SHELL_RC="${HOME}/.zshrc"
    ;;
  fish)
    COMPLETION_SCRIPT="$TOOLKIT_ROOT/completions/git-shadow.fish"
    FISH_COMPLETIONS_DIR="${HOME}/.config/fish/completions"
    ;;
  *)
    echo "⚠️  Could not detect shell from \$SHELL='${SHELL:-}'."
    printf '\n  Manually source the appropriate completion script:\n'
    printf '    Bash: source %s/completions/git-shadow.bash\n' "$TOOLKIT_ROOT"
    printf '    Zsh:  source %s/completions/git-shadow.zsh\n'  "$TOOLKIT_ROOT"
    printf '    Fish: ln -sf %s/completions/git-shadow.fish ~/.config/fish/completions/git-shadow.fish\n' "$TOOLKIT_ROOT"
    exit 0
    ;;
esac

# ---------------------------------------------------------------------------
# Verify completion script exists
# ---------------------------------------------------------------------------

if [[ ! -f "$COMPLETION_SCRIPT" ]]; then
  echo "❌ Completion script not found: $COMPLETION_SCRIPT" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Install — fish uses a symlink in ~/.config/fish/completions/
#           bash/zsh use a source line appended to the shell rc file
# ---------------------------------------------------------------------------

if [[ "$SHELL_NAME" == "fish" ]]; then
  FISH_COMPLETION_DEST="$FISH_COMPLETIONS_DIR/git-shadow.fish"

  if [[ -L "$FISH_COMPLETION_DEST" && "$(readlink "$FISH_COMPLETION_DEST")" == "$COMPLETION_SCRIPT" ]]; then
    echo "ℹ️  Shell completion already installed in: $FISH_COMPLETION_DEST"
    exit 0
  fi

  mkdir -p "$FISH_COMPLETIONS_DIR"
  if ln -sf "$COMPLETION_SCRIPT" "$FISH_COMPLETION_DEST" 2>/dev/null; then
    echo "✅ Shell completion installed for fish: $FISH_COMPLETION_DEST"
  else
    cp "$COMPLETION_SCRIPT" "$FISH_COMPLETION_DEST"
    echo "✅ Shell completion installed for fish (copied): $FISH_COMPLETION_DEST"
  fi
  exit 0
fi

if [[ -f "$SHELL_RC" ]] && grep -Fq "$COMPLETION_MARKER" "$SHELL_RC"; then
  echo "ℹ️  Shell completion already installed in: $SHELL_RC"
  exit 0
fi

printf '\n%s\nsource "%s"\n' "$COMPLETION_MARKER" "$COMPLETION_SCRIPT" >> "$SHELL_RC"

echo "✅ Shell completion installed for $SHELL_NAME in: $SHELL_RC"
printf '   Reload your shell or run: source %s\n' "$SHELL_RC"
