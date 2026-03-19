#!/usr/bin/env bats

# Tests for: git shadow config list | show | get | set | unset

setup() {
  TEST_DIR="$(mktemp -d)"
  XDG_DIR="$(mktemp -d)"
  export XDG_CONFIG_HOME="$XDG_DIR"
  cd "$TEST_DIR"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  echo "initial" > file.txt
  git add file.txt
  git commit -qm "initial"
}

teardown() {
  rm -rf "$TEST_DIR" "$XDG_DIR"
}

# ---------------------------------------------------------------------------
# config list
# ---------------------------------------------------------------------------

@test "config list exits 0" {
  run git shadow config list
  [ "$status" -eq 0 ]
}

@test "config list includes LOCAL_SUFFIX" {
  run git shadow config list
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
}

@test "config list includes all known keys" {
  run git shadow config list
  [[ "$output" == *"PUBLIC_BASE_BRANCH"* ]]
  [[ "$output" == *"SHADOW_COMMIT_PREFIX"* ]]
  [[ "$output" == *"HOOK_CHECK_MARKER"* ]]
}

@test "config list --json exits 0" {
  run git shadow config list --json
  [ "$status" -eq 0 ]
}

@test "config list --json outputs a JSON array" {
  run git shadow config list --json
  [[ "$output" == "["* ]]
  [[ "$output" == *"]" ]]
}

@test "config list --json contains key and default fields" {
  run git shadow config list --json
  [[ "$output" == *'"key":"LOCAL_SUFFIX"'* ]]
  [[ "$output" == *'"default":"@local"'* ]]
}

# ---------------------------------------------------------------------------
# config show
# ---------------------------------------------------------------------------

@test "config show exits 0" {
  run git shadow config show
  [ "$status" -eq 0 ]
}

@test "config show displays LOCAL_SUFFIX with default source" {
  run git shadow config show
  [[ "$output" == *"LOCAL_SUFFIX"* ]]
  [[ "$output" == *"source: defaults"* ]]
}

@test "config show reflects project override" {
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config show
  [[ "$output" == *"@proj"* ]]
  [[ "$output" == *"source: project"* ]]
}

@test "config show reflects user override" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@user"' > "$XDG_CONFIG_HOME/git-shadow/config.env"
  run git shadow config show
  [[ "$output" == *"@user"* ]]
  [[ "$output" == *"source: user"* ]]
}

@test "config show --json outputs a JSON object" {
  run git shadow config show --json
  [ "$status" -eq 0 ]
  [[ "$output" == "{"* ]]
  [[ "$output" == *"}" ]]
}

@test "config show --json contains value and source fields" {
  run git shadow config show --json
  [[ "$output" == *'"value":'* ]]
  [[ "$output" == *'"source":'* ]]
}

@test "config show --json source is project when project config is set" {
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config show --json
  [[ "$output" == *'"source": "project"'* ]]
}

# ---------------------------------------------------------------------------
# config get
# ---------------------------------------------------------------------------

@test "config get exits 1 when no KEY given" {
  run git shadow config get
  [ "$status" -eq 1 ]
}

@test "config get exits 1 for unknown key" {
  run git shadow config get UNKNOWN_KEY_XYZ
  [ "$status" -eq 1 ]
}

@test "config get returns default value for LOCAL_SUFFIX" {
  run git shadow config get LOCAL_SUFFIX
  [ "$status" -eq 0 ]
  [[ "$output" == *"@local"* ]]
}

@test "config get shows source: defaults when not overridden" {
  run git shadow config get LOCAL_SUFFIX
  [[ "$output" == *"source: defaults"* ]]
}

@test "config get returns project value when set in .git-shadow.env" {
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config get LOCAL_SUFFIX
  [[ "$output" == *"@proj"* ]]
  [[ "$output" == *"source: project"* ]]
}

@test "config get returns user value when set in user config" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@user"' > "$XDG_CONFIG_HOME/git-shadow/config.env"
  run git shadow config get LOCAL_SUFFIX
  [[ "$output" == *"@user"* ]]
  [[ "$output" == *"source: user"* ]]
}

@test "config get --json returns valid JSON with key, value, source" {
  run git shadow config get LOCAL_SUFFIX --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"key":"LOCAL_SUFFIX"'* ]]
  [[ "$output" == *'"value":"@local"'* ]]
  [[ "$output" == *'"source":"defaults"'* ]]
}

@test "config get: project overrides user" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@user"' > "$XDG_CONFIG_HOME/git-shadow/config.env"
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config get LOCAL_SUFFIX
  [[ "$output" == *"@proj"* ]]
  [[ "$output" == *"source: project"* ]]
}

# ---------------------------------------------------------------------------
# config set
# ---------------------------------------------------------------------------

@test "config set --project-config exits 0" {
  run git shadow config set LOCAL_SUFFIX=@test --project-config
  [ "$status" -eq 0 ]
}

@test "config set --project-config creates .git-shadow.env" {
  git shadow config set LOCAL_SUFFIX=@test --project-config
  [ -f "$TEST_DIR/.git-shadow.env" ]
}

@test "config set --project-config writes KEY=VALUE to project file" {
  git shadow config set LOCAL_SUFFIX=@test --project-config
  grep -q 'LOCAL_SUFFIX="@test"' "$TEST_DIR/.git-shadow.env"
}

@test "config set KEY VALUE form works" {
  run git shadow config set LOCAL_SUFFIX @spaced --project-config
  [ "$status" -eq 0 ]
  grep -q 'LOCAL_SUFFIX="@spaced"' "$TEST_DIR/.git-shadow.env"
}

@test "config set --user-config creates user config file" {
  run git shadow config set LOCAL_SUFFIX=@user --user-config
  [ "$status" -eq 0 ]
  [ -f "$XDG_CONFIG_HOME/git-shadow/config.env" ]
}

@test "config set --user-config writes to user config" {
  git shadow config set LOCAL_SUFFIX=@user --user-config
  grep -q 'LOCAL_SUFFIX="@user"' "$XDG_CONFIG_HOME/git-shadow/config.env"
}

@test "config set updates existing key without duplication" {
  git shadow config set LOCAL_SUFFIX=@first --project-config
  git shadow config set LOCAL_SUFFIX=@second --project-config
  count="$(grep -c '^LOCAL_SUFFIX=' "$TEST_DIR/.git-shadow.env")"
  [ "$count" -eq 1 ]
  grep -q 'LOCAL_SUFFIX="@second"' "$TEST_DIR/.git-shadow.env"
}

@test "config set warns on unknown key but still writes" {
  run git shadow config set UNKNOWN_KEY_XYZ=foo --project-config
  [ "$status" -eq 0 ]
  grep -q 'UNKNOWN_KEY_XYZ="foo"' "$TEST_DIR/.git-shadow.env"
}

@test "config set exits 1 in non-TTY mode without scope flag" {
  run git shadow config set LOCAL_SUFFIX=@test
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# config unset
# ---------------------------------------------------------------------------

@test "config unset exits 1 when no KEY given" {
  run git shadow config unset
  [ "$status" -eq 1 ]
}

@test "config unset --project-config removes key from project file" {
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config unset LOCAL_SUFFIX --project-config
  [ "$status" -eq 0 ]
  ! grep -q '^LOCAL_SUFFIX=' "$TEST_DIR/.git-shadow.env"
}

@test "config unset --user-config removes key from user config" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'LOCAL_SUFFIX="@user"' > "$XDG_CONFIG_HOME/git-shadow/config.env"
  run git shadow config unset LOCAL_SUFFIX --user-config
  [ "$status" -eq 0 ]
  ! grep -q '^LOCAL_SUFFIX=' "$XDG_CONFIG_HOME/git-shadow/config.env"
}

@test "config unset is a no-op when file does not exist" {
  run git shadow config unset LOCAL_SUFFIX --project-config
  [ "$status" -eq 0 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "config unset is a no-op when key is not in file" {
  echo 'PUBLIC_BASE_BRANCH="develop"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config unset LOCAL_SUFFIX --project-config
  [ "$status" -eq 0 ]
  [[ "$output" == *"not set"* ]]
}

@test "config unset exits 1 in non-TTY mode without scope flag" {
  echo 'LOCAL_SUFFIX="@proj"' > "$TEST_DIR/.git-shadow.env"
  run git shadow config unset LOCAL_SUFFIX
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Integration: set -> get -> unset cycle
# ---------------------------------------------------------------------------

@test "set then get reflects new value" {
  git shadow config set LOCAL_SUFFIX=@cycle --project-config
  run git shadow config get LOCAL_SUFFIX
  [[ "$output" == *"@cycle"* ]]
}

@test "set then unset falls back to default" {
  git shadow config set LOCAL_SUFFIX=@cycle --project-config
  git shadow config unset LOCAL_SUFFIX --project-config
  run git shadow config get LOCAL_SUFFIX
  [[ "$output" == *"@local"* ]]
  [[ "$output" == *"source: defaults"* ]]
}

# ---------------------------------------------------------------------------
# Unknown key warnings in env loading
# ---------------------------------------------------------------------------

@test "env warns about unknown key in project config" {
  echo 'TOTALLY_UNKNOWN_KEY=foo' > "$TEST_DIR/.git-shadow.env"
  run git shadow config show
  [[ "$output" == *"TOTALLY_UNKNOWN_KEY"* ]] || [[ "${lines[@]}" == *"TOTALLY_UNKNOWN_KEY"* ]]
}

@test "env warns about unknown key in user config" {
  mkdir -p "$XDG_CONFIG_HOME/git-shadow"
  echo 'TOTALLY_UNKNOWN_KEY=bar' > "$XDG_CONFIG_HOME/git-shadow/config.env"
  run git shadow config show
  [[ "$output" == *"TOTALLY_UNKNOWN_KEY"* ]] || [[ "${lines[@]}" == *"TOTALLY_UNKNOWN_KEY"* ]]
}
