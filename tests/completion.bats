#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
COMPLETION_BASH="$REPO_ROOT/completions/git-shadow.bash"
COMPLETION_ZSH="$REPO_ROOT/completions/git-shadow.zsh"
COMPLETION_INSTALL="$REPO_ROOT/commands/completion/install.sh"

# ---------------------------------------------------------------------------
# Bash completion
# ---------------------------------------------------------------------------

@test "bash completion file exists" {
  [ -f "$COMPLETION_BASH" ]
}

@test "bash completion can be sourced without errors" {
  run bash -c "source '$COMPLETION_BASH' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "bash completion defines _git_shadow function" {
  run bash -c "source '$COMPLETION_BASH' && declare -f _git_shadow >/dev/null && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

_bash_complete() {
  # Simulate bash completion for a given COMP_WORDS array and COMP_CWORD index.
  # Usage: _bash_complete <cword> word0 word1 ...
  local cword="$1"; shift
  bash -c "
    source '$COMPLETION_BASH'
    COMP_WORDS=($*)
    COMP_CWORD=$cword
    _git_shadow
    echo \"\${COMPREPLY[*]}\"
  "
}

@test "bash completion suggests top-level commands" {
  run _bash_complete 1 git-shadow ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"config"* ]]
  [[ "$output" == *"doctor"* ]]
  [[ "$output" == *"commit"* ]]
  [[ "$output" == *"version"* ]]
}

@test "bash completion filters top-level commands by prefix" {
  run _bash_complete 1 git-shadow 'fe'
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature"* ]]
  [[ "$output" != *"config"* ]]
}

@test "bash completion suggests feature subcommands" {
  run _bash_complete 2 git-shadow feature ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"start"* ]]
  [[ "$output" == *"publish"* ]]
  [[ "$output" == *"finish"* ]]
}

@test "bash completion suggests flags for feature publish" {
  run _bash_complete 3 git-shadow feature publish ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"--commit"* ]]
  [[ "$output" == *"-m"* ]]
}

@test "bash completion suggests flags for feature finish" {
  run _bash_complete 3 git-shadow feature finish ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"--keep-branches"* ]]
  [[ "$output" == *"--no-pull"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "bash completion suggests config subcommands" {
  run _bash_complete 2 git-shadow config ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"show"* ]]
  [[ "$output" == *"get"* ]]
  [[ "$output" == *"set"* ]]
  [[ "$output" == *"unset"* ]]
}

@test "bash completion suggests --json for config show" {
  run _bash_complete 3 git-shadow config show ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"--json"* ]]
}

@test "bash completion suggests --json for config get after key" {
  run _bash_complete 4 git-shadow config get LOCAL_SUFFIX ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"--json"* ]]
}

@test "bash completion suggests --project-config and --user-config for config set after key" {
  run _bash_complete 4 git-shadow config set LOCAL_SUFFIX ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"--project-config"* ]]
  [[ "$output" == *"--user-config"* ]]
}

@test "bash completion suggests config keys for config get" {
  run _bash_complete 3 git-shadow config get ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
  [[ "$output" == *"SHADOW_COMMIT_PREFIX"* ]]
  [[ "$output" == *"PUBLIC_BASE_BRANCH"* ]]
}

@test "bash completion suggests config keys for config set" {
  run _bash_complete 3 git-shadow config set ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
  [[ "$output" == *"AUTO_PULL_BASE_BRANCHES"* ]]
}

@test "bash completion suggests config keys for config unset" {
  run _bash_complete 3 git-shadow config unset ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
}

@test "bash completion filters config keys by prefix" {
  run _bash_complete 3 git-shadow config get 'LOCAL'
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
  [[ "$output" == *"LOCAL_COMMENT_PATTERN"* ]]
  [[ "$output" != *"PUBLIC_BASE_BRANCH"* ]]
}

@test "bash completion suggests --json for status" {
  run _bash_complete 2 git-shadow status ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"--json"* ]]
}

@test "bash completion suggests -m for commit" {
  run _bash_complete 2 git-shadow commit ''
  [ "$status" -eq 0 ]
  [[ "$output" == *"-m"* ]]
}

@test "bash completion works for git shadow invocation (offset 2)" {
  run bash -c "
    source '$COMPLETION_BASH'
    COMP_WORDS=(git shadow '')
    COMP_CWORD=2
    _git_shadow
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"status"* ]]
}

@test "bash completion works for git shadow feature (offset 2)" {
  run bash -c "
    source '$COMPLETION_BASH'
    COMP_WORDS=(git shadow feature '')
    COMP_CWORD=3
    _git_shadow
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"start"* ]]
  [[ "$output" == *"publish"* ]]
}

# ---------------------------------------------------------------------------
# Zsh completion
# ---------------------------------------------------------------------------

@test "zsh completion file exists" {
  [ -f "$COMPLETION_ZSH" ]
}

# ---------------------------------------------------------------------------
# Fish completion
# ---------------------------------------------------------------------------

COMPLETION_FISH="$REPO_ROOT/completions/git-shadow.fish"

@test "fish completion file exists" {
  [ -f "$COMPLETION_FISH" ]
}

@test "zsh completion has valid syntax" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -n "$COMPLETION_ZSH"
  [ "$status" -eq 0 ]
}

@test "zsh completion defines _git_shadow function" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git_shadow >/dev/null && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "zsh completion defines _git-shadow alias for git integration" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git-shadow >/dev/null && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "zsh completion defines all subcommand helper functions" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "
    source '$COMPLETION_ZSH' 2>/dev/null
    typeset -f _git_shadow_commands >/dev/null || exit 1
    typeset -f _git_shadow_feature >/dev/null || exit 1
    typeset -f _git_shadow_feature_subcommands >/dev/null || exit 1
    typeset -f _git_shadow_config >/dev/null || exit 1
    typeset -f _git_shadow_config_subcommands >/dev/null || exit 1
    echo ok
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "zsh completion _git_shadow_commands body mentions expected commands" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git_shadow_commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"config"* ]]
  [[ "$output" == *"doctor"* ]]
}

@test "zsh completion _git_shadow_feature_subcommands body mentions start publish finish" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git_shadow_feature_subcommands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"start"* ]]
  [[ "$output" == *"publish"* ]]
  [[ "$output" == *"finish"* ]]
}

@test "zsh completion _git_shadow_config_subcommands body mentions list show get set unset" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git_shadow_config_subcommands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"show"* ]]
  [[ "$output" == *"get"* ]]
  [[ "$output" == *"set"* ]]
  [[ "$output" == *"unset"* ]]
}

@test "zsh completion _git_shadow_feature body mentions publish flags" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git_shadow_feature"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--commit"* ]]
  [[ "$output" == *"--keep-branches"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "zsh completion _git_shadow_config body mentions --json and --project-config" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  run zsh -c "source '$COMPLETION_ZSH' 2>/dev/null; typeset -f _git_shadow_config"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--json"* ]]
  [[ "$output" == *"--project-config"* ]]
  [[ "$output" == *"--user-config"* ]]
}

# ---------------------------------------------------------------------------
# Fish completion
# ---------------------------------------------------------------------------

@test "fish completion has valid syntax" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -n "$COMPLETION_FISH"
  [ "$status" -eq 0 ]
}

@test "fish completion suggests all top-level commands" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"config"* ]]
  [[ "$output" == *"doctor"* ]]
  [[ "$output" == *"commit"* ]]
  [[ "$output" == *"version"* ]]
  [[ "$output" == *"completion"* ]]
}

@test "fish completion suggests feature subcommands" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow feature '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"start"* ]]
  [[ "$output" == *"publish"* ]]
  [[ "$output" == *"finish"* ]]
}

@test "fish completion suggests flags for feature publish" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow feature publish -'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--commit"* ]]
  [[ "$output" == *"-m"* ]]
}

@test "fish completion suggests flags for feature finish" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow feature finish -'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--keep-branches"* ]]
  [[ "$output" == *"--no-pull"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "fish completion suggests config subcommands" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow config '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"show"* ]]
  [[ "$output" == *"get"* ]]
  [[ "$output" == *"set"* ]]
  [[ "$output" == *"unset"* ]]
}

@test "fish completion suggests --json for config show" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow config show -'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--json"* ]]
}

@test "fish completion suggests --project-config and --user-config for config set" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow config set -'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--project-config"* ]]
  [[ "$output" == *"--user-config"* ]]
}

@test "fish completion suggests config keys for config get" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow config get '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
  [[ "$output" == *"SHADOW_COMMIT_PREFIX"* ]]
  [[ "$output" == *"PUBLIC_BASE_BRANCH"* ]]
}

@test "fish completion suggests config keys for config set" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow config set '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
  [[ "$output" == *"AUTO_PULL_BASE_BRANCHES"* ]]
}

@test "fish completion suggests config keys for config unset" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow config unset '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
}

@test "fish completion suggests --json for status" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow status -'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--json"* ]]
}

@test "fish completion suggests install for completion subcommand" {
  command -v fish >/dev/null 2>&1 || skip "fish not installed"
  run fish -c "source '$COMPLETION_FISH'; complete -C 'git-shadow completion '"
  [ "$status" -eq 0 ]
  [[ "$output" == *"install"* ]]
}

# ---------------------------------------------------------------------------
# completion install command
# ---------------------------------------------------------------------------

@test "completion install script exists and is executable" {
  [ -x "$COMPLETION_INSTALL" ]
}

@test "completion install writes source line to ~/.bashrc" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  run env HOME="$tmp_home" SHELL="/bin/bash" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  grep -q "git-shadow completion" "$tmp_home/.bashrc"
  grep -q "git-shadow.bash" "$tmp_home/.bashrc"
  rm -rf "$tmp_home"
}

@test "completion install is idempotent (does not write twice)" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  env HOME="$tmp_home" SHELL="/bin/bash" bash "$COMPLETION_INSTALL"
  env HOME="$tmp_home" SHELL="/bin/bash" bash "$COMPLETION_INSTALL"
  local count
  count="$(grep -c "git-shadow completion" "$tmp_home/.bashrc")"
  [ "$count" -eq 1 ]
  rm -rf "$tmp_home"
}

@test "completion install reports already installed on second run" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  env HOME="$tmp_home" SHELL="/bin/bash" bash "$COMPLETION_INSTALL"
  run env HOME="$tmp_home" SHELL="/bin/bash" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
  rm -rf "$tmp_home"
}

@test "completion install appends to existing ~/.bashrc without overwriting" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  echo "export FOO=bar" > "$tmp_home/.bashrc"
  env HOME="$tmp_home" SHELL="/bin/bash" bash "$COMPLETION_INSTALL"
  grep -q "export FOO=bar" "$tmp_home/.bashrc"
  grep -q "git-shadow.bash" "$tmp_home/.bashrc"
  rm -rf "$tmp_home"
}

@test "completion install writes source line to ~/.zshrc" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  local tmp_home
  tmp_home="$(mktemp -d)"
  run env HOME="$tmp_home" SHELL="/usr/bin/zsh" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  grep -q "git-shadow completion" "$tmp_home/.zshrc"
  grep -q "git-shadow.zsh" "$tmp_home/.zshrc"
  rm -rf "$tmp_home"
}

@test "completion install for zsh is idempotent" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  local tmp_home
  tmp_home="$(mktemp -d)"
  env HOME="$tmp_home" SHELL="/usr/bin/zsh" bash "$COMPLETION_INSTALL"
  run env HOME="$tmp_home" SHELL="/usr/bin/zsh" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
  rm -rf "$tmp_home"
}

@test "completion install handles unknown shell gracefully" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  run env HOME="$tmp_home" SHELL="/usr/bin/nushell" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Could not detect shell"* ]]
  rm -rf "$tmp_home"
}

@test "completion install creates symlink in fish completions dir" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  run env HOME="$tmp_home" SHELL="/usr/bin/fish" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  [ -e "$tmp_home/.config/fish/completions/git-shadow.fish" ]
  rm -rf "$tmp_home"
}

@test "completion install for fish is idempotent" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  env HOME="$tmp_home" SHELL="/usr/bin/fish" bash "$COMPLETION_INSTALL"
  run env HOME="$tmp_home" SHELL="/usr/bin/fish" bash "$COMPLETION_INSTALL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
  rm -rf "$tmp_home"
}

@test "git shadow completion install runs via dispatcher" {
  local tmp_home
  tmp_home="$(mktemp -d)"
  run env HOME="$tmp_home" SHELL="/bin/bash" git shadow completion install
  [ "$status" -eq 0 ]
  rm -rf "$tmp_home"
}

# ---------------------------------------------------------------------------
# Source of truth: commands/ directory vs completion scripts
#
# These tests act as a safety net: if a command is added to commands/ but
# the completion scripts are not updated, the tests will fail.
#
# Internal commands not exposed to users must be listed in INTERNAL_COMMANDS.
# ---------------------------------------------------------------------------

INTERNAL_COMMANDS="check-shadow-push"

_user_facing_toplevel_commands() {
  # Emit one command name per line from commands/*.sh and commands/*/
  for f in "$REPO_ROOT/commands/"*.sh; do
    local cmd
    cmd="$(basename "$f" .sh)"
    [[ " $INTERNAL_COMMANDS " == *" $cmd "* ]] && continue
    echo "$cmd"
  done
  for d in "$REPO_ROOT/commands"/*/; do
    [[ -d "$d" ]] || continue
    echo "$(basename "$d")"
  done
}

_subcommands_for() {
  local group="$1"
  for f in "$REPO_ROOT/commands/${group}/"*.sh; do
    [[ -f "$f" ]] || continue
    basename "$f" .sh
  done
}

@test "all user-facing commands in commands/ appear in bash completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_BASH" || missing+=("$cmd")
  done < <(_user_facing_toplevel_commands)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from bash completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all user-facing commands in commands/ appear in zsh completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_ZSH" || missing+=("$cmd")
  done < <(_user_facing_toplevel_commands)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from zsh completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all user-facing commands in commands/ appear in fish completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_FISH" || missing+=("$cmd")
  done < <(_user_facing_toplevel_commands)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from fish completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all feature subcommands in commands/feature/ appear in bash completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_BASH" || missing+=("$cmd")
  done < <(_subcommands_for feature)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from bash completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all feature subcommands in commands/feature/ appear in zsh completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_ZSH" || missing+=("$cmd")
  done < <(_subcommands_for feature)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from zsh completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all feature subcommands in commands/feature/ appear in fish completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_FISH" || missing+=("$cmd")
  done < <(_subcommands_for feature)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from fish completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all config subcommands in commands/config/ appear in bash completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_BASH" || missing+=("$cmd")
  done < <(_subcommands_for config)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from bash completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all config subcommands in commands/config/ appear in zsh completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_ZSH" || missing+=("$cmd")
  done < <(_subcommands_for config)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from zsh completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all config subcommands in commands/config/ appear in fish completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_FISH" || missing+=("$cmd")
  done < <(_subcommands_for config)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from fish completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all completion subcommands in commands/completion/ appear in bash completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_BASH" || missing+=("$cmd")
  done < <(_subcommands_for completion)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from bash completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all completion subcommands in commands/completion/ appear in zsh completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_ZSH" || missing+=("$cmd")
  done < <(_subcommands_for completion)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from zsh completion: ${missing[*]}" >&2
    return 1
  }
}

@test "all completion subcommands in commands/completion/ appear in fish completion" {
  local missing=()
  while IFS= read -r cmd; do
    grep -q "$cmd" "$COMPLETION_FISH" || missing+=("$cmd")
  done < <(_subcommands_for completion)
  [ "${#missing[@]}" -eq 0 ] || {
    echo "Missing from fish completion: ${missing[*]}" >&2
    return 1
  }
}
