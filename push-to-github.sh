#!/bin/bash
# Renewly — push this project to a PRIVATE GitHub repo.
# Run once from Terminal:  bash push-to-github.sh
# Requires: git + an SSH key added to your GitHub account (already done).
set -e
cd "$(dirname "$0")"

# 1. git identity (needed for the first commit)
if [ -z "$(git config user.name 2>/dev/null)" ]; then
  read -p "Your name for git commits: " GIT_NAME
  git config user.name "$GIT_NAME"
fi
if [ -z "$(git config user.email 2>/dev/null)" ]; then
  read -p "Your email for git commits: " GIT_EMAIL
  git config user.email "$GIT_EMAIL"
fi

# 2. init + commit
if [ ! -d .git ]; then
  git init -b main 2>/dev/null || git init
fi
git add -A
git commit -m "Renewly iOS — subscription tracker (private)" 2>/dev/null \
  || echo "(nothing new to commit)"

# 3. screenshots sanity check
for s in home alerts stats settings; do
  [ -f "screenshots/$s.png" ] || echo "⚠️  screenshots/$s.png missing — add it later and push again."
done

# 4. create the PRIVATE repo + push
if git remote get-url origin >/dev/null 2>&1; then
  echo "Remote already set — pushing..."
  git push -u origin main
elif command -v gh >/dev/null 2>&1; then
  echo "Creating PRIVATE repo 'Renewly-iOS' on GitHub..."
  gh repo create Renewly-iOS --private --source=. --remote=origin --push
  echo "✅ Done — your code is on GitHub in a private repo."
else
  echo ""
  echo "GitHub CLI not found. Do this once on github.com:"
  echo "  1. Open https://github.com/new"
  echo "  2. Name it Renewly-iOS and choose PRIVATE (important!)."
  echo "  3. Don't add a README/license — then click Create."
  echo "  4. Back here, run:"
  echo ""
  echo "     git remote add origin git@github.com:YOURNAME/Renewly-iOS.git"
  echo "     git push -u origin main"
fi
