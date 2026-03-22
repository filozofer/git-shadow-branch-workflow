#!/usr/bin/env bash
# -------------------------------------------------------------------
# Demo setup script – sourced by demo.tape (hidden section).
# Creates a fresh throw-away project with git-shadow already wired.
# -------------------------------------------------------------------
set -euo pipefail

DEMO=$(mktemp -d)
cd "$DEMO"

git init -q
git config user.name  "Alice"
git config user.email "alice@example.com"

echo "# my-app" > README.md
git add README.md
git commit -qm "init"

# Start feature branch (creates auth + auth@local, checks out auth@local)
git shadow feature start auth > /dev/null 2>&1

# Pre-stage the source file with local comments.
# LC holds the local-comment marker so this script isn't itself flagged.
LC='///'
cat > auth.ts << EOF
${LC} Get user from DB — returns null if not found
const user = await db.findOne({ email })
if (!user) throw new Error('Invalid credentials')

${LC} bcrypt takes ~100ms — skip awaiting in hot paths
const valid = await bcrypt.compare(password, user.hash)
if (!valid) throw new Error('Bad password')

return createSession(user)
EOF

git add auth.ts

# Clean, minimal prompt for the recording
export PS1='\[\033[0;32m\]❯\[\033[0m\] '
