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
  # Create a feature branch pair and add a commit with a local comment
  git shadow feature start test-feature
  printf '/// local comment\nreal code\n' > feature.txt
  git add feature.txt
  git shadow commit -m "feat: real code"
  # Now on test-feature@local with 2 commits: feat + [MEMORY]
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "feature publish exits 1 when not on a @local branch" {
  git checkout -q test-feature
  run git shadow feature publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"@local"* ]]
}

@test "feature publish exits 0 from a @local branch" {
  run git shadow feature publish
  [ "$status" -eq 0 ]
}

@test "feature publish cherry-picks the code commit to the public branch" {
  git shadow feature publish
  git checkout -q test-feature
  result="$(git log --oneline)"
  [[ "$result" == *"feat: real code"* ]]
}

@test "feature publish skips [MEMORY] commits from the public branch" {
  git shadow feature publish
  git checkout -q test-feature
  result="$(git log --oneline)"
  [[ "$result" != *"[MEMORY]"* ]]
}

@test "feature publish outputs a completion message" {
  run git shadow feature publish
  [ "$status" -eq 0 ]
  [[ "$output" == *"Publish completed"* ]]
}

@test "feature publish exits 0 with no publishable commits (already up to date)" {
  git shadow feature publish
  git checkout -q "test-feature@local"
  run git shadow feature publish
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# promote + publish integration tests
# ---------------------------------------------------------------------------

_setup_promote() {
  # Add a shadow-only file via a [MEMORY] commit so it is NOT cherry-picked
  # (simulates a file that lives only in the shadow branch history)
  echo "shadow notes" > shadow-notes.txt
  git add shadow-notes.txt
  git commit -qm "[MEMORY] docs: private shadow notes"
}

@test "feature publish handles promote commit: creates shadow publish commit on public branch" {
  _setup_promote
  git shadow promote shadow-notes.txt
  git shadow feature publish
  git checkout -q test-feature
  run git log --oneline
  [[ "$output" == *"shadow: publish shadow-notes.txt"* ]]
}

@test "feature publish handles promote commit: file exists on public branch after publish" {
  _setup_promote
  git shadow promote shadow-notes.txt
  git shadow feature publish
  git checkout -q test-feature
  [ -f shadow-notes.txt ]
  [ "$(cat shadow-notes.txt)" = "shadow notes" ]
}

@test "feature publish handles promote commit: promote commit is not cherry-picked raw" {
  _setup_promote
  git shadow promote shadow-notes.txt
  git shadow feature publish
  git checkout -q test-feature
  run git log --oneline
  [[ "$output" != *"shadow: promote"* ]]
}

@test "feature publish pre-flight fails when modified file missing on public branch" {
  _setup_promote
  # Modify shadow-notes.txt in a regular commit WITHOUT promoting first
  echo "updated" > shadow-notes.txt
  git add shadow-notes.txt
  git commit -qm "docs: update shadow notes"
  # Publish without promote — should fail pre-flight
  run git shadow feature publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"git shadow promote"* ]]
}

@test "feature publish pre-flight passes when promote precedes modifying commit" {
  _setup_promote
  git shadow promote shadow-notes.txt
  # Modify the file in a regular commit after promoting
  echo "updated" > shadow-notes.txt
  git add shadow-notes.txt
  git commit -qm "docs: update shadow notes"
  run git shadow feature publish
  [ "$status" -eq 0 ]
}
