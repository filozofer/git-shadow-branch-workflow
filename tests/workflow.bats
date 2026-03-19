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
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "complete workflow: feature start -> commit -> feature publish -> feature finish" {
  # 1. Create feature branches
  run git shadow feature start workflow-feature
  [ "$status" -eq 0 ]
  # We are now on workflow-feature@local

  # 2. Add code (plain, no local comments — stripping is tested in commit.bats)
  echo "public code" > feature.txt
  git add feature.txt
  run git shadow commit -m "feat: public code"
  [ "$status" -eq 0 ]

  # 3. Publish: cherry-picks code commit to workflow-feature (switches us there)
  run git shadow feature publish
  [ "$status" -eq 0 ]

  # 4. Verify public branch has the code commit
  git checkout -q workflow-feature
  result="$(git log --oneline)"
  [[ "$result" == *"feat: public code"* ]]

  # 5. Simulate merge into main
  git checkout -q main
  git merge -q --no-edit workflow-feature

  # 6. Finish feature
  git checkout -q "workflow-feature@local"
  run git shadow feature finish --no-pull
  [ "$status" -eq 0 ]

  # 7. Feature branches are deleted
  run git branch --list "workflow-feature"
  [ -z "$output" ]
  run git branch --list "workflow-feature@local"
  [ -z "$output" ]

  # 8. main@local contains the feature commit
  git checkout -q "main@local"
  result="$(git log --oneline)"
  [[ "$result" == *"feat: public code"* ]]
}

@test "MEMORY commits are not published to public branch" {
  git shadow feature start memory-feature
  # Add a MEMORY commit (prefix [MEMORY] to skip publish)
  echo "memory content" > memory.md
  git add memory.md
  git commit -qm "[MEMORY] agent context"
  # Add a normal code commit
  echo "public code" > code.txt
  git add code.txt
  git shadow commit -m "feat: code"

  run git shadow feature publish
  [ "$status" -eq 0 ]

  git checkout -q memory-feature
  result="$(git log --oneline)"
  [[ "$result" != *"[MEMORY]"* ]]
  [[ "$result" == *"feat: code"* ]]
}
