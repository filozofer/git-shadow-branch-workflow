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

@test "check-local-comments exits 1 when staged file contains triple-dash HTML comment" {
  printf '<!--- local note --->\nnormal code\n' > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 1 ]
}

@test "check-local-comments exits 0 for regular HTML comment (<!-- not <!---)" {
  printf '<!-- regular comment -->\nnormal code\n' > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments skips excluded file types (*.md by default)" {
  printf '## This is a markdown H2 heading\ncontent\n' > README.md
  git add README.md
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments skips *.md even when other .md files exist (glob expansion bug)" {
  # Regression: when multiple .md files exist, *.md in LOCAL_COMMENT_EXCLUDE must
  # stay as a glob pattern, not expand to the list of actual filenames.
  echo "other" > other.md
  printf '/// local comment\ncontent\n' > docs.md
  git add other.md docs.md
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments skips excluded file types (*.json by default)" {
  printf '{\n  "key": "## not a comment"\n}\n' > config.json
  git add config.json
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments processes non-excluded file with ## marker" {
  printf '## local note\nreal code\n' > script.sh
  git add script.sh
  run git shadow check-local-comments
  [ "$status" -eq 1 ]
}

@test "check-local-comments respects custom LOCAL_COMMENT_EXCLUDE via project config" {
  # Exclude .sh files from processing
  printf 'LOCAL_COMMENT_EXCLUDE="*.sh"\n' > .git-shadow.env
  printf '/// local comment\ncode\n' > script.sh
  git add script.sh
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments respects custom LOCAL_COMMENT_PATTERN via project config" {
  # Custom pattern: only ### is a local marker; default /// is no longer matched
  printf 'LOCAL_COMMENT_PATTERN="^[[:space:]]*(###)"\n' > .git-shadow.env
  printf '/// triple slash — not a local comment with custom pattern\ncode\n' > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 0 ]
}

@test "check-local-comments detects custom LOCAL_COMMENT_PATTERN marker" {
  printf 'LOCAL_COMMENT_PATTERN="^[[:space:]]*(###)"\n' > .git-shadow.env
  printf '### custom local comment\ncode\n' > file.txt
  git add file.txt
  run git shadow check-local-comments
  [ "$status" -eq 1 ]
}
