#!/bin/sh

# Run all Bats tests for git-shadow

# Check if Bats is installed
if ! command -v bats &> /dev/null; then
  echo "Bats is not installed. Please install it first."
  echo "On macOS: brew install bats-core"
  echo "On Ubuntu: sudo apt-get install bats"
  echo "On Windows: Use WSL or install via npm: `npm install -g bats`"
  exit 1
fi

# Run all .bats files
bats tests/*.bats