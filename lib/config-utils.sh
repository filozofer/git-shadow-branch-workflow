#!/usr/bin/env bash
# -------------------------------------------------------------------
# Library: config-utils.sh
# Purpose: shared utilities for git shadow config commands.
#
# NOTE: Must NOT source env.sh or common.sh — it is part of the
#       config loading foundation itself.
# -------------------------------------------------------------------

# Compute TOOLKIT_ROOT independently (same idiom as env.sh).
_CFG_TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DEFAULTS_FILE="$_CFG_TOOLKIT_ROOT/config/defaults.env"

# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------

user_config_path() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/git-shadow/config.env"
}

project_config_path() {
  printf '%s\n' "$PWD/.git-shadow.env"
}

# ---------------------------------------------------------------------------
# Parsing config/defaults.env
# ---------------------------------------------------------------------------

# Emit newline-separated list of all known key names.
config_known_keys() {
  grep -E '^[A-Z_][A-Z0-9_]*=' "$DEFAULTS_FILE" | sed 's/=.*//'
}

# Return 0 if KEY is defined in defaults.env, 1 otherwise.
config_is_known_key() {
  grep -qE "^${1}=" "$DEFAULTS_FILE"
}

# Return the default value for KEY (outer quotes stripped), or empty string.
config_default_value() {
  local key="$1"
  local raw
  raw="$(grep -E "^${key}=" "$DEFAULTS_FILE" | head -1)"
  [[ -n "$raw" ]] || return 1
  local val="${raw#*=}"
  # Strip only the outermost matching pair of quotes.
  if [[ "$val" == \"*\" ]]; then
    val="${val#\"}"
    val="${val%\"}"
  elif [[ "$val" == \'*\' ]]; then
    val="${val#\'}"
    val="${val%\'}"
  fi
  printf '%s\n' "$val"
}

# Return the human-readable description for KEY.
# Description = the comment line immediately before the key assignment,
# unless that line is a separator (# ---...) or blank.
config_description() {
  local key="$1"
  local prev=""
  local line
  while IFS= read -r line; do
    if [[ "$line" =~ ^${key}= ]]; then
      # Accept the previous line only if it looks like a description comment.
      if [[ "$prev" =~ ^#[[:space:]] ]] && ! [[ "$prev" =~ ^#[[:space:]]*-{3,} ]]; then
        printf '%s\n' "${prev#\# }"
      fi
      return 0
    fi
    prev="$line"
  done < "$DEFAULTS_FILE"
}

# ---------------------------------------------------------------------------
# Reading values from arbitrary config files (without sourcing them)
# ---------------------------------------------------------------------------

# Return the value of KEY from FILE (last matching line, quotes stripped).
# Returns exit code 1 if FILE does not exist or KEY is absent.
config_value_in_file() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 1
  local raw
  raw="$(grep -E "^${key}=" "$file" | tail -1)"
  [[ -n "$raw" ]] || return 1
  local val="${raw#*=}"
  if [[ "$val" == \"*\" ]]; then
    val="${val#\"}"
    val="${val%\"}"
  elif [[ "$val" == \'*\' ]]; then
    val="${val#\'}"
    val="${val%\'}"
  fi
  printf '%s\n' "$val"
}

# Determine which tier holds the effective value for KEY:
# Returns "project", "user", or "defaults".
config_source_of() {
  local key="$1"
  local project_config user_config
  project_config="$(project_config_path)"
  user_config="$(user_config_path)"
  if config_value_in_file "$project_config" "$key" >/dev/null 2>&1; then
    printf 'project\n'
  elif config_value_in_file "$user_config" "$key" >/dev/null 2>&1; then
    printf 'user\n'
  else
    printf 'defaults\n'
  fi
}

# ---------------------------------------------------------------------------
# Writing / removing values in config files
# ---------------------------------------------------------------------------

# Map scope name to config file path.
config_file_for_scope() {
  case "$1" in
    project) project_config_path ;;
    user)    user_config_path ;;
    *)       printf 'Unknown scope: %s\n' "$1" >&2; return 1 ;;
  esac
}

# Upsert KEY="VALUE" in FILE. Creates the file (and parent dirs) if absent.
# Fully portable: uses a tmpfile loop instead of sed -i.
config_set_in_file() {
  local file="$1" key="$2" value="$3"
  # Escape embedded double-quotes in value.
  local escaped_value="${value//\"/\\\"}"
  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    printf '%s="%s"\n' "$key" "$escaped_value" > "$file"
    return 0
  fi
  if grep -qE "^${key}=" "$file"; then
    # Replace the existing line in-place via tmpfile.
    local tmp
    tmp="$(mktemp)"
    while IFS= read -r line; do
      if [[ "$line" =~ ^${key}= ]]; then
        printf '%s="%s"\n' "$key" "$escaped_value"
      else
        printf '%s\n' "$line"
      fi
    done < "$file" > "$tmp"
    mv "$tmp" "$file"
  else
    # Append a new entry.
    printf '%s="%s"\n' "$key" "$escaped_value" >> "$file"
  fi
}

# Remove all lines matching ^KEY= from FILE.
# No-op if FILE does not exist or KEY is not present.
config_unset_in_file() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  grep -qE "^${key}=" "$file" || return 0
  local tmp
  tmp="$(mktemp)"
  grep -vE "^${key}=" "$file" > "$tmp" || true
  mv "$tmp" "$file"
}

# ---------------------------------------------------------------------------
# Interactive scope selector
# ---------------------------------------------------------------------------

# Prompt the user to choose a scope (project or user).
# Outputs "project" or "user" on stdout; prompts go to stderr.
# Exits 1 if stdin is not a TTY.
config_prompt_scope() {
  local action="${1:-write}"
  if [[ ! -t 0 ]]; then
    printf '❌ Specify --project-config or --user-config (stdin is not a TTY).\n' >&2
    return 1
  fi
  local project_config user_config
  project_config="$(project_config_path)"
  user_config="$(user_config_path)"
  printf '\nWhere should the value be %s?\n' "$action" >&2
  printf '  1) Project config  (%s)\n' "$project_config" >&2
  printf '  2) User config     (%s)\n' "$user_config" >&2
  local choice
  while true; do
    printf 'Choice [1/2]: ' >&2
    read -r choice
    case "$choice" in
      1) printf 'project\n'; return 0 ;;
      2) printf 'user\n';    return 0 ;;
      *) printf 'Please enter 1 or 2.\n' >&2 ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------

# Escape a string for safe embedding inside a JSON double-quoted value.
_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"   # backslash
  s="${s//\"/\\\"}"   # double-quote
  printf '%s' "$s"
}
