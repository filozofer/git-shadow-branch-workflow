#!/usr/bin/env bats

# Tests for the three-tier configuration system.
# Precedence (highest to lowest):
#   project (.git-shadow.env) > user (~/.config/git-shadow/config.env) > built-in defaults

setup() {
  TEST_DIR="$(mktemp -d)"
  XDG_DIR="$(mktemp -d)"

  # Isolate user-level config: point XDG_CONFIG_HOME to a clean temp dir
  export XDG_CONFIG_HOME="$XDG_DIR"

  cd "$TEST_DIR"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  git symbolic-ref HEAD refs/heads/main
  echo "initial" > file.txt
  git add file.txt
  git commit -qm "initial"
}

teardown() {
  rm -rf "$TEST_DIR" "$XDG_DIR"
}

# ---------------------------------------------------------------------------
# Tier 1 – built-in defaults (config/defaults.env)
# ---------------------------------------------------------------------------

@test "defaults: LOCAL_SUFFIX is @local" {
  # feature start creates a branch with LOCAL_SUFFIX appended
  run git shadow feature start my-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/my-feature@local"
}

@test "defaults: PUBLIC_BASE_BRANCH is main" {
  run git shadow feature start my-feature
  [ "$status" -eq 0 ]
  # The public feature branch is created from main
  git show-ref --verify --quiet "refs/heads/my-feature"
}

# ---------------------------------------------------------------------------
# Tier 2 – user-level config overrides defaults
# ---------------------------------------------------------------------------

@test "user config overrides LOCAL_SUFFIX" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@mine"' > "$XDG_CONFIG_HOME/git-shadow/config.env"

  run git shadow feature start my-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/my-feature@mine"
}

# ---------------------------------------------------------------------------
# Tier 3 – project-level config overrides user config
# ---------------------------------------------------------------------------

@test "project config overrides user config for LOCAL_SUFFIX" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@user"' > "$XDG_CONFIG_HOME/git-shadow/config.env"
  echo 'LOCAL_SUFFIX="@project"' > "$TEST_DIR/.git-shadow.env"

  run git shadow feature start my-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/my-feature@project"
}

@test "project config alone overrides defaults for LOCAL_SUFFIX" {
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"

  run git shadow feature start my-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/my-feature@proj"
}

# ---------------------------------------------------------------------------
# Isolation – no cross-contamination between tiers
# ---------------------------------------------------------------------------

@test "user config does not affect other projects without .git-shadow.env" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@user"' > "$XDG_CONFIG_HOME/git-shadow/config.env"

  # No project-level config: user value should be used, not default
  run git shadow feature start my-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/my-feature@user"
  # Default @local branch must NOT exist
  run git show-ref --verify "refs/heads/my-feature@local"
  [ "$status" -ne 0 ]
}
