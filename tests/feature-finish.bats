#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  git symbolic-ref HEAD refs/heads/main
  echo "initial" > file.txt
  git add file.txt
  git commit -qm "initial"
  git checkout -q -b "main@local"
  git checkout -q main

  # Create feature, add code, publish
  git shadow feature start test-feature
  echo "feature code" > feature.txt
  git add feature.txt
  git shadow commit -m "feat: feature code"
  git shadow feature publish
  # Simulate the feature being merged into main
  git checkout -q main
  git merge -q --no-edit test-feature

  # Return to the local feature branch so feature finish can detect it
  git checkout -q "test-feature@local"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "feature finish exits 0 after feature is merged into develop" {
  run git shadow feature finish --no-pull
  [ "$status" -eq 0 ]
}

@test "feature finish outputs completion message" {
  run git shadow feature finish --no-pull
  [[ "$output" == *"Feature finished successfully"* ]]
}

@test "feature finish merges feature commits into main@local" {
  git shadow feature finish --no-pull
  git checkout -q "main@local"
  result="$(git log --oneline)"
  [[ "$result" == *"feat: feature code"* ]]
}

@test "feature finish deletes the public feature branch" {
  git shadow feature finish --no-pull
  run git branch --list "test-feature"
  [ -z "$output" ]
}

@test "feature finish deletes the local feature branch" {
  git shadow feature finish --no-pull
  run git branch --list "test-feature@local"
  [ -z "$output" ]
}

@test "feature finish exits 1 when run from the base branch" {
  git checkout -q main
  run git shadow feature finish --no-pull
  [ "$status" -eq 1 ]
}
