#!/usr/bin/env bash
# Stop hook: auto-commit any pending changes and push the current branch.
# Restricted to claude/* branches to avoid auto-pushing to main.

cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch=$(git rev-parse --abbrev-ref HEAD)
case "$branch" in
  claude/*) ;;
  *) printf '{"systemMessage":"auto-push skipped: branch %s is not claude/*"}\n' "$branch"; exit 0 ;;
esac

if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "Auto-commit from Claude Code session" >/dev/null 2>&1 || true
fi

ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "1")
if [ "$ahead" = "0" ]; then
  printf '{"systemMessage":"auto-push: nothing to push (%s up-to-date)"}\n' "$branch"
  exit 0
fi

if out=$(git push -u origin "$branch" 2>&1); then
  printf '{"systemMessage":"auto-push: %s ✓"}\n' "$branch"
else
  esc=$(printf '%s' "$out" | tr '\n' ' ' | sed 's/"/\\"/g')
  printf '{"systemMessage":"auto-push failed: %s"}\n' "$esc"
fi
