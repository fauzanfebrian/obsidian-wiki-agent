#!/usr/bin/env bash
set -e

VAULT_PATH=$(cd "$(dirname "$0")" && pwd)

# ── Guard: already initialized? ──────────────────────────────────
if ! grep -q '<ABSOLUTE_PATH_TO_VAULT>' .mcp 2>/dev/null && \
   ! grep -q '<ABSOLUTE_PATH_TO_VAULT>' .rules 2>/dev/null; then
  echo "[!] Already initialized (no placeholders found)."
  echo "    Vault path: $VAULT_PATH"
  echo "    To re-initialize, restore <ABSOLUTE_PATH_TO_VAULT> placeholders and re-run."
  exit 0
fi

echo "Setting up vault at: $VAULT_PATH"

# ── Create directory structure ────────────────────────────────────
mkdir -p raw wiki/sources wiki/entities wiki/concepts

# ── Scaffold wiki files (only if missing) ─────────────────────────
if [ ! -f wiki/index.md ]; then
  cat > wiki/index.md <<'EOF'
# Wiki Index

## Sources

## Concepts

## Entities
EOF
  echo "  Created wiki/index.md"
fi

if [ ! -f wiki/log.md ]; then
  cat > wiki/log.md <<'EOF'
# Wiki Log
EOF
  echo "  Created wiki/log.md"
fi

# ── Replace path placeholders ─────────────────────────────────────
sedi() {
  if [[ "$OSTYPE" == darwin* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

for f in .mcp .rules; do
  if [ -f "$f" ]; then
    sedi "s|<ABSOLUTE_PATH_TO_VAULT>|$VAULT_PATH|g" "$f"
    echo "  Configured $f"
  fi
done

rm .gitignore
rm -rf .git

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo "Done. Next steps:"
echo "  1. Make sure Docker is running."
echo "  2. Point your AI IDE to the .mcp file for MCP settings."
echo "  3. Open this folder in Obsidian."
