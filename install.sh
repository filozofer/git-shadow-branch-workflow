#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# git-shadow installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/filozofer/git-shadow/main/install.sh | bash
#
# Environment variables (optional overrides):
#   GIT_SHADOW_HOME    — where to install the toolkit  (default: ~/.local/share/git-shadow)
#   GIT_SHADOW_BIN     — where to place the binary      (default: ~/.local/bin)
#   GIT_SHADOW_VERSION — specific version to install    (default: latest release)
# -------------------------------------------------------------------

REPO_URL="https://github.com/filozofer/git-shadow.git"
RELEASES_API="https://api.github.com/repos/filozofer/git-shadow/releases/latest"
INSTALL_DIR="${GIT_SHADOW_HOME:-$HOME/.local/share/git-shadow}"
BIN_DIR="${GIT_SHADOW_BIN:-$HOME/.local/bin}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_info()    { printf '  %s\n' "$*"; }
_success() { printf '✅ %s\n' "$*"; }
_warn()    { printf '⚠️  %s\n' "$*" >&2; }
_error()   { printf '❌ %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

printf '\n🌑 Installing git-shadow...\n\n'

command -v curl >/dev/null 2>&1 || _error "curl is required but was not found in PATH."

# ---------------------------------------------------------------------------
# Install via git clone (preferred) or tarball fallback
# ---------------------------------------------------------------------------

if command -v git >/dev/null 2>&1; then
  # --- git path ---
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    _info "Existing installation found at $INSTALL_DIR — updating..."
    git -C "$INSTALL_DIR" fetch --quiet origin
    git -C "$INSTALL_DIR" reset --quiet --hard origin/main
    _success "Updated to latest version."
  else
    _info "Cloning into $INSTALL_DIR ..."
    git clone --quiet --depth=1 "$REPO_URL" "$INSTALL_DIR"
    _success "Cloned successfully."
  fi
else
  # --- tarball fallback (no git required) ---
  _info "git not found — downloading release tarball..."

  if [[ -n "${GIT_SHADOW_VERSION:-}" ]]; then
    TAG="v${GIT_SHADOW_VERSION#v}"
  else
    _info "Fetching latest release tag..."
    TAG="$(curl -fsSL "$RELEASES_API" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
    [[ -n "$TAG" ]] || _error "Could not determine latest release tag."
  fi

  TARBALL_URL="https://github.com/filozofer/git-shadow/archive/refs/tags/${TAG}.tar.gz"
  _info "Downloading ${TAG} from ${TARBALL_URL} ..."

  mkdir -p "$INSTALL_DIR"
  curl -fsSL "$TARBALL_URL" | tar -xz --strip-components=1 -C "$INSTALL_DIR"
  _success "Downloaded and extracted ${TAG}."
fi

# ---------------------------------------------------------------------------
# Make scripts executable
# ---------------------------------------------------------------------------

chmod +x "$INSTALL_DIR/bin/git-shadow"
find "$INSTALL_DIR/commands" "$INSTALL_DIR/lib" "$INSTALL_DIR/scripts" \
  -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# ---------------------------------------------------------------------------
# Create symlink in BIN_DIR (copy fallback for Windows/Git Bash)
# ---------------------------------------------------------------------------

mkdir -p "$BIN_DIR"
if ln -sf "$INSTALL_DIR/bin/git-shadow" "$BIN_DIR/git-shadow" 2>/dev/null; then
  _success "Binary linked: $BIN_DIR/git-shadow → $INSTALL_DIR/bin/git-shadow"
else
  # Symlinks unavailable (e.g. Git Bash without Windows Developer Mode).
  # Copy the launcher instead; re-run install.sh after updating.
  cp "$INSTALL_DIR/bin/git-shadow" "$BIN_DIR/git-shadow"
  chmod +x "$BIN_DIR/git-shadow"
  _success "Binary copied to $BIN_DIR/git-shadow (symlinks unavailable)"
  _warn "Re-run install.sh after updating git-shadow to refresh the binary."
fi

# ---------------------------------------------------------------------------
# PATH check
# ---------------------------------------------------------------------------

printf '\n'
if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
  _success "$BIN_DIR is already in your PATH."
  printf '\n  Run: git shadow help\n\n'
else
  _warn "$BIN_DIR is not in your PATH."
  printf '\n  Add the following line to your shell profile (~/.bashrc, ~/.zshrc, etc.):\n\n'
  printf '    export PATH="%s:$PATH"\n\n' "$BIN_DIR"
  printf '  Then reload your shell:\n\n'
  printf '    source ~/.bashrc   # or source ~/.zshrc\n\n'
  printf '  Then run: git shadow help\n\n'
fi

# ---------------------------------------------------------------------------
# Shell completion
# ---------------------------------------------------------------------------

printf '🔧 Installing shell completion...\n'
"$INSTALL_DIR/commands/completion/install.sh" || _warn "Shell completion setup failed. Run 'git shadow completion install' manually."
