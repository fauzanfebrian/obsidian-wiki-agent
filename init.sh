#!/usr/bin/env bash
set -e

VAULT_PATH=$(cd "$(dirname "$0")" && pwd)

# Derive a namespace from the vault directory name so multiple cloned
# vaults on the same machine don't collide in QMD's global index.
# Lowercase, strip non-alphanumerics → dashes, collapse repeats, trim.
VAULT_SLUG=$(basename "$VAULT_PATH" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
[ -z "$VAULT_SLUG" ] && VAULT_SLUG="vault"
WIKI_COLLECTION="${VAULT_SLUG}-wiki"
RAW_COLLECTION="${VAULT_SLUG}-raw"

# ── Guard: already initialized? ──────────────────────────────────
if ! grep -q '<ABSOLUTE_PATH_TO_VAULT>' .mcp 2>/dev/null && \
   ! grep -q '<ABSOLUTE_PATH_TO_VAULT>' .rules 2>/dev/null; then
  echo "[!] Already initialized (no placeholders found)."
  echo "    Vault path: $VAULT_PATH"
  echo "    To re-initialize, restore <ABSOLUTE_PATH_TO_VAULT> placeholders and re-run."
  exit 0
fi

echo "Setting up vault at: $VAULT_PATH"
echo "Collection namespace: $VAULT_SLUG (wiki=$WIKI_COLLECTION, raw=$RAW_COLLECTION)"

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
    sedi "s|<QMD_WIKI_COLLECTION>|$WIKI_COLLECTION|g" "$f"
    sedi "s|<QMD_RAW_COLLECTION>|$RAW_COLLECTION|g" "$f"
    echo "  Configured $f"
  fi
done

rm .gitignore
rm -rf .git

# ── QMD bootstrap ─────────────────────────────────────────────────
# QMD is the mandatory search engine for this vault. We invoke it via
# `npx @tobilu/qmd` so a global install isn't required (Node >= 22 is).
if command -v npx >/dev/null 2>&1; then
  echo ""
  echo "Bootstrapping QMD (search engine)..."
  QMD="npx -y @tobilu/qmd"

  # Register collections (idempotent — `collection add` updates path/mask if name exists).
  # Names are vault-namespaced so multiple cloned vaults coexist in QMD's global index.
  $QMD collection add "$VAULT_PATH/wiki" --name "$WIKI_COLLECTION" --mask "**/*.md" >/dev/null 2>&1 \
    && echo "  Registered collection: $WIKI_COLLECTION -> wiki/" \
    || echo "  [!] Failed to register '$WIKI_COLLECTION' (run 'npx @tobilu/qmd collection add' manually)"

  $QMD collection add "$VAULT_PATH/raw" --name "$RAW_COLLECTION" --mask "**/*.md" >/dev/null 2>&1 \
    && echo "  Registered collection: $RAW_COLLECTION -> raw/" \
    || echo "  [!] Failed to register '$RAW_COLLECTION' (run 'npx @tobilu/qmd collection add' manually)"

  # Seed contexts so retrieval results carry semantic hints
  $QMD context add "qmd://$WIKI_COLLECTION" "Agent-maintained knowledge base for vault '$VAULT_SLUG': synthesized pages for entities, concepts, and source summaries." >/dev/null 2>&1 || true
  $QMD context add "qmd://$RAW_COLLECTION"  "Immutable raw source documents for vault '$VAULT_SLUG': articles, transcripts, papers, exports." >/dev/null 2>&1 || true
  echo "  Seeded path contexts ($WIKI_COLLECTION, $RAW_COLLECTION)"
else
  echo ""
  echo "[!] 'npx' not found. Install Node.js >= 22 — QMD is required for this vault."
  echo "    See https://github.com/tobi/qmd"
fi

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo "Done. Next steps:"
echo "  1. Make sure Docker is running (for the markdownify MCP server)."
echo "  2. Point your AI IDE to the .mcp file for MCP settings."
echo "  3. Open this folder in Obsidian."
echo "  4. After dropping initial sources into raw/, run:"
echo "       npx @tobilu/qmd update    # index files"
echo "       npx @tobilu/qmd embed     # generate vector embeddings"
echo ""
echo "  Collections registered as: $WIKI_COLLECTION, $RAW_COLLECTION"
echo "  Search this vault with:    npx @tobilu/qmd query \"...\" -c $WIKI_COLLECTION"
