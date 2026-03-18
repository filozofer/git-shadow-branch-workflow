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
  git shadow new-feature test-feature
  printf '/// local comment\nreal code\n' > feature.txt
  git add feature.txt
  git shadow commit -m "feat: real code"
  # Now on test-feature@local with 2 commits: feat + [COMMENTS]
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "publish exits 1 when not on a @local branch" {
  git checkout -q test-feature
  run git shadow publish
  [ "$status" -eq 1 ]
  [[ "$output" == *"@local"* ]]
}

@test "publish exits 0 from a @local branch" {
  run git shadow publish
  [ "$status" -eq 0 ]
}

@test "publish cherry-picks the code commit to the public branch" {
  git shadow publish
  git checkout -q test-feature
  result="$(git log --oneline)"
  [[ "$result" == *"feat: real code"* ]]
}

@test "publish skips [COMMENTS] commits from the public branch" {
  git shadow publish
  git checkout -q test-feature
  result="$(git log --oneline)"
  [[ "$result" != *"[COMMENTS]"* ]]
}

@test "publish outputs a completion message" {
  run git shadow publish
  [ "$status" -eq 0 ]
  [[ "$output" == *"Publish completed"* ]]
}

@test "publish exits 0 with no publishable commits (already up to date)" {
  git shadow publish
  git checkout -q "test-feature@local"
  run git shadow publish
  [ "$status" -eq 0 ]
}
