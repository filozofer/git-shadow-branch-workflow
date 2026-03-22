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
  # Create a feature branch pair
  git shadow feature start test-feature
  # Now on test-feature@local; add a shadow-only file
  echo "shadow content" > shadow-only.txt
  git add shadow-only.txt
  git commit -qm "docs: add shadow-only file"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "promote exits 1 when not on a @local branch" {
  git checkout -q test-feature
  run git shadow promote shadow-only.txt
  [ "$status" -eq 1 ]
  [[ "$output" == *"@local"* ]]
}

@test "promote exits 1 when file does not exist in shadow branch" {
  run git shadow promote nonexistent.txt
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

@test "promote exits 1 when file already exists on public branch" {
  # Publish via regular cherry-pick so shadow-only.txt lands on test-feature
  git shadow feature publish
  git checkout -q "test-feature@local"
  # Now try to promote it — should fail since it's already on public
  run git shadow promote shadow-only.txt
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists on public branch"* ]]
}

@test "promote exits 0 and creates a promote commit" {
  run git shadow promote shadow-only.txt
  [ "$status" -eq 0 ]
  subject="$(git log -1 --pretty=%s)"
  [ "$subject" = "shadow: promote shadow-only.txt" ]
}

@test "promote commit body contains path= and blob=" {
  git shadow promote shadow-only.txt
  body="$(git log -1 --pretty=%B)"
  [[ "$body" == *"path=shadow-only.txt"* ]]
  [[ "$body" == *"blob="* ]]
}

@test "promote commit blob SHA matches the file content" {
  git shadow promote shadow-only.txt
  blob="$(git log -1 --pretty=%B | grep '^blob=' | cut -d= -f2-)"
  expected_blob="$(git rev-parse "HEAD~1:shadow-only.txt")"
  [ "$blob" = "$expected_blob" ]
}

@test "promote exits 1 with no arguments" {
  run git shadow promote
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}
