#!/usr/bin/env bash

# -------------------------------------------------------------------
# Library: ui.sh
# Purpose: semantic output helpers aligned with the git-shadow design system.
#
# Design system:
#   🟢 Green  (#10B981) → public / git / collaboration operations
#   🟣 Purple (#7C3AED) → shadow / local / thinking operations
#   ⚪ Neutral           → info, steps, structural output
#   🔴 Red              → errors (stderr)
#   🟡 Yellow           → warnings (stderr)
#
# Colors are auto-disabled when:
#   - NO_COLOR is set (https://no-color.org/)
#   - stdout is not a terminal (piping, CI capture)
#   - terminal reports fewer than 8 colors
# -------------------------------------------------------------------

_ui_colors_enabled() {
  [[ -n "${NO_COLOR:-}" ]]            && return 1
  [[ -n "${GIT_SHADOW_NO_COLOR:-}" ]] && return 1
  [[ ! -t 1 ]]                        && return 1
  command -v tput >/dev/null 2>&1     || return 1
  [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]] || return 1
  return 0
}

if _ui_colors_enabled; then
  _C_GREEN='\033[38;2;16;185;129m'   # #10B981 — public / git
  _C_PURPLE='\033[38;2;124;58;237m'  # #7C3AED — shadow / local
  _C_RED='\033[38;2;239;68;68m'      # errors
  _C_YELLOW='\033[38;2;234;179;8m'   # warnings
  _C_BOLD='\033[1m'
  _C_RESET='\033[0m'
else
  _C_GREEN='' _C_PURPLE='' _C_RED='' _C_YELLOW='' _C_BOLD='' _C_RESET=''
fi

# ── Semantic output helpers ───────────────────────────────────────────────────

# Public / git / collaboration operations  →  green 🌿
ui_git()    { printf "${_C_GREEN}🌿 %s${_C_RESET}\n"   "$*"; }

# Shadow / local / thinking operations    →  purple 🧠
ui_shadow() { printf "${_C_PURPLE}🧠 %s${_C_RESET}\n"  "$*"; }

# Completed action                        →  green ✅
ui_ok()     { printf "${_C_GREEN}✅ %s${_C_RESET}\n"   "$*"; }

# Neutral info                            →  plain ℹ️
ui_info()   { printf "ℹ️  %s\n" "$*"; }

# Indented sub-step / structural label    →  plain
ui_step()   { printf "   %s\n" "$*"; }

# Skipped item                            →  plain ⏭️
ui_skip()   { printf "⏭️  %s\n" "$*"; }

# Warning                                 →  yellow ⚠️  (stderr)
ui_warn()   { printf "${_C_YELLOW}⚠️  %s${_C_RESET}\n" "$*" >&2; }

# Error                                   →  red ❌  (stderr)
ui_error()  { printf "${_C_RED}❌ %s${_C_RESET}\n"     "$*" >&2; }
