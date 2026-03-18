#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "install-hook exits 0" {
  run git shadow install-hook
  [ "$status" -eq 0 ]
}

@test "install-hook creates .git/hooks/pre-commit file" {
  git shadow install-hook
  [ -f ".git/hooks/pre-commit" ]
}

@test "install-hook makes the hook executable" {
  git shadow install-hook
  [ -x ".git/hooks/pre-commit" ]
}

@test "install-hook is idempotent (exits 0 when already installed)" {
  git shadow install-hook
  run git shadow install-hook
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
