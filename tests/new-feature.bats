#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  git symbolic-ref HEAD refs/heads/develop
  echo "initial" > file.txt
  git add file.txt
  git commit -qm "initial"
  git checkout -q -b "develop@local"
  git checkout -q develop
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "new-feature exits 1 when no argument given" {
  run git shadow new-feature
  [ "$status" -eq 1 ]
}

@test "new-feature creates the public feature branch" {
  run git shadow new-feature test-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/test-feature"
}

@test "new-feature creates the local shadow branch" {
  run git shadow new-feature test-feature
  [ "$status" -eq 0 ]
  git show-ref --verify --quiet "refs/heads/test-feature@local"
}

@test "new-feature switches to the local shadow branch" {
  run git shadow new-feature test-feature
  [ "$status" -eq 0 ]
  current="$(git branch --show-current)"
  [ "$current" = "test-feature@local" ]
}

@test "new-feature exits 1 when branch name already exists" {
  git shadow new-feature test-feature
  run git shadow new-feature test-feature
  [ "$status" -eq 1 ]
}
