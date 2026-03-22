# -------------------------------------------------------------------
# git-shadow demo — VHS tape
# Run from repo root:  vhs docs/demo/demo.tape
# Requires: vhs (https://github.com/charmbracelet/vhs), git-shadow
# -------------------------------------------------------------------

Output docs/demo/demo.gif
Output docs/demo/demo.mp4

Set Shell       "bash"
Set FontSize    15
Set Width       1000
Set Height      560
Set Theme       "Catppuccin Mocha"
Set TypingSpeed 60ms
Set PlaybackSpeed 1

# ── Silent setup (not shown in recording) ────────────────────────────────────
Hide
  Type `source docs/demo/setup.sh` Enter
  Sleep 3s
  Type `clear` Enter
  Sleep 200ms
Show

# ── 1. Show the staged file — local annotations visible ──────────────────────
Sleep 500ms
Type `cat auth.ts`
Enter
Sleep 3s

# ── 2. Commit via git shadow — strips comments, keeps shadow copy ─────────────
Sleep 300ms
Type `git shadow commit -m "feat(auth): login flow"`
Enter
Sleep 4s

# ── 3. Two commits created: public + [MEMORY] ────────────────────────────────
Sleep 200ms
Type `git log --oneline`
Enter
Sleep 2500ms

# ── 4. Public commit is clean — no /// in sight ───────────────────────────────
Sleep 300ms
Type `git show HEAD~1:auth.ts`
Enter
Sleep 4s

Sleep 1s
