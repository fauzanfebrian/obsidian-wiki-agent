#!/usr/bin/env bash
set -e

# Configuration
REPO_URL="https://github.com/fauzanfebrian/obsidian-wiki-agent"
BRANCH="main"
VAULT_PATH=$(cd "$(dirname "$0")" && pwd)

echo "Setting up temporary Git context..."

# ── 1. Setup Git ──────────────────────────────────────────────────
git init -q

# ── 2. Setup Origin ───────────────────────────────────────────────
git remote add origin "$REPO_URL"

# ── 3. Checkout main branch ───────────────────────────────────────
git checkout -b "$BRANCH" -q 2>/dev/null || git checkout "$BRANCH" -q

# ── 4. Pull/Rebase/Merge ───────────────────────────────────────────
echo "Syncing with $REPO_URL ($BRANCH)..."
git fetch origin "$BRANCH" -q

[ -d ".obsidian" ] && mv .obsidian .obsidian_backup

# This hard reset will now safely execute without touching your .obsidian folder
git reset --hard "origin/$BRANCH"

# Use rebase to apply local modifications on top of template updates
if ! git pull --rebase origin "$BRANCH" -q; then
  echo "Conflict detected! Please resolve manually."
  echo "Leaving .git directory for resolution. Delete it manually after fixing."
  exit 1
fi

if [ -d ".obsidian_backup" ]; then
  rm -rf .obsidian
  mv .obsidian_backup .obsidian
fi

# ── Post-Sync: Restore Path Placeholders ──────────────────────────
./init.sh

echo "Sync complete. Vault updated and detached."
