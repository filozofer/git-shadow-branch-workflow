#!/usr/bin/env bats

# Helper: set up a repo with develop + develop@local + a completed feature
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

  # Create feature, add code, publish
  git shadow new-feature test-feature
  echo "feature code" > feature.txt
  git add feature.txt
  git shadow commit -m "feat: feature code"
  git shadow publish
  # Simulate the feature being merged into develop
  git checkout -q develop
  git merge -q --no-edit test-feature

  # Return to the local feature branch so finish-feature can detect it
  git checkout -q "test-feature@local"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "finish-feature exits 0 after feature is merged into develop" {
  run git shadow finish-feature --no-pull
  [ "$status" -eq 0 ]
}

@test "finish-feature outputs completion message" {
  run git shadow finish-feature --no-pull
  [[ "$output" == *"Feature finished successfully"* ]]
}

@test "finish-feature merges feature commits into develop@local" {
  git shadow finish-feature --no-pull
  git checkout -q "develop@local"
  result="$(git log --oneline)"
  [[ "$result" == *"feat: feature code"* ]]
}

@test "finish-feature deletes the public feature branch" {
  git shadow finish-feature --no-pull
  run git branch --list "test-feature"
  [ -z "$output" ]
}

@test "finish-feature deletes the local feature branch" {
  git shadow finish-feature --no-pull
  run git branch --list "test-feature@local"
  [ -z "$output" ]
}

@test "finish-feature exits 1 when run from the base branch" {
  git checkout -q develop
  run git shadow finish-feature --no-pull
  [ "$status" -eq 1 ]
}
