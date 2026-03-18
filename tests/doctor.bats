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

@test "doctor exits 0 from inside a git repo" {
  run git shadow doctor
  [ "$status" -eq 0 ]
}

@test "doctor reports toolkit files present" {
  run git shadow doctor
  [[ "$output" == *"Toolkit files present"* ]]
}

@test "doctor reports configuration template valid" {
  run git shadow doctor
  [[ "$output" == *"Configuration template valid"* ]]
}

@test "doctor reports git CLI available" {
  run git shadow doctor
  [[ "$output" == *"git CLI available"* ]]
}
