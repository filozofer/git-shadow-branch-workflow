#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  echo "initial" > file.txt
  git add file.txt
  git commit -qm "initial"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "check-local-comments exits 0 when no staged files" {
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments exits 0 when staged files have no local comments" {
  echo "normal code without comments" > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments exits 1 when staged file contains triple-slash comment" {
  printf '/// local comment\nnormal code\n' > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 1 ]
  [[ "$output" == *"local comments"* ]]
}

@test "check-local-comments exits 1 when staged file contains double-hash comment" {
  printf '## local comment\nnormal code\n' > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 1 ]
}

@test "check-local-comments reports the file name containing comments" {
  printf '/// comment\ncode\n' > myfile.txt
  git add myfile.txt
  run git shadow check-local-comments
  [ "$status" -eq 1 ]
  [[ "$output" == *"myfile.txt"* ]]
}
