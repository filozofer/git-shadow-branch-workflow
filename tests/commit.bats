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

@test "commit exits 1 when no staged changes" {
  run git shadow commit -m "test"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No staged changes"* ]]
}

@test "commit exits 0 with staged changes" {
  echo "new code" > feature.txt
  git add feature.txt
  run git shadow commit -m "feat: new feature"
  [ "$status" -eq 0 ]
}

@test "commit creates a commit with the given message" {
  echo "new code" > feature.txt
  git add feature.txt
  git shadow commit -m "feat: my feature"
  result="$(git log --oneline)"
  [[ "$result" == *"feat: my feature"* ]]
}

@test "commit strips local comments from the public commit" {
  printf '/// local comment\nreal code\n' > feature.txt
  git add feature.txt
  git shadow commit -m "feat: real code"
  # The first (public) commit should not contain the local comment
  result="$(git show HEAD~1:feature.txt)"
  [[ "$result" != *"/// local comment"* ]]
  [[ "$result" == *"real code"* ]]
}

@test "commit creates a [MEMORY] commit when local comments are present" {
  printf '/// local comment\nreal code\n' > feature.txt
  git add feature.txt
  git shadow commit -m "feat: real code"
  last_msg="$(git log -1 --pretty=%s)"
  [[ "$last_msg" == "[MEMORY]"* ]]
}

@test "commit does not create a [MEMORY] commit when no local comments" {
  echo "plain code without comments" > feature.txt
  git add feature.txt
  git shadow commit -m "feat: plain"
  commit_count="$(git log --oneline | wc -l)"
  # Only 2 commits: initial + feat:plain (no MEMORY commit)
  [ "$commit_count" -eq 2 ]
}

@test "commit does not strip ## from excluded file types (*.md)" {
  printf '## Section heading\ncontent\n' > README.md
  git add README.md
  git shadow commit -m "docs: readme"
  # Public commit must still have the ## heading
  result="$(git show HEAD:README.md)"
  [[ "$result" == *"## Section heading"* ]]
}

@test "commit does not strip ## from excluded file types (*.yaml)" {
  printf 'key: value\n## comment\n' > config.yaml
  git add config.yaml
  git shadow commit -m "chore: config"
  result="$(git show HEAD:config.yaml)"
  [[ "$result" == *"## comment"* ]]
}

@test "commit strips ## from non-excluded source files" {
  printf '## local note\nreal_function()\n' > script.sh
  git add script.sh
  git shadow commit -m "chore: script"
  # Public commit should not have the ## line
  result="$(git show HEAD~1:script.sh 2>/dev/null || git show HEAD:script.sh)"
  [[ "$result" != *"## local note"* ]]
}

@test "commit strips <!--- marker (triple-dash HTML comment)" {
  printf '<!--- local note --->\nreal code\n' > file.html
  git add file.html
  git shadow commit -m "feat: html"
  result="$(git show HEAD~1:file.html 2>/dev/null || git show HEAD:file.html)"
  [[ "$result" != *"<!--- local note"* ]]
}

@test "commit does not strip regular <!-- HTML comment" {
  printf '<!-- regular comment -->\nreal code\n' > file.html
  git add file.html
  git shadow commit -m "feat: html"
  result="$(git show HEAD:file.html)"
  [[ "$result" == *"<!-- regular comment -->"* ]]
}
