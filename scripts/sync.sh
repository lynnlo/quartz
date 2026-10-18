#!/usr/bin/env bash
#
# sync.sh — copy whitelisted Obsidian vault directories into Quartz content/.
#
# Two usage modes:
#   LOCAL (your laptop):  defaults to the vault at the path below.
#       ./scripts/sync.sh
#   CI (GitHub Actions):  pass the checked-out vault as $1.
#       ./scripts/sync.sh /tmp/vault
#
# Only directories listed in VAULT_DIRS are imported. Anything else in the
# vault (50MB PDFs, dictionary.txt, .obsidian, Excalidraw source, scripts,
# hidden plugin data) never reaches the public site.
#
# Safe to run repeatedly — content/ is fully rebuilt from scratch each time.
set -euo pipefail

# --- Edit the vault path below for LOCAL runs ---------------------------------
LOCAL_VAULT="/c/Users/tharl/Document/Obsidian Vault"
# ==============================================================================

# Directory of this script, used to locate content/ relative to the repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_DIR="$SCRIPT_DIR/../content"

# The vault source. In CI the workflow clones the vault repo and passes its
# path here; locally we fall back to LOCAL_VAULT.
VAULT="${1:-$LOCAL_VAULT}"

if [[ ! -d "$VAULT" ]]; then
  echo "ERROR: vault directory not found at '$VAULT'" >&2
  echo "Usage: ./scripts/sync.sh [path-to-vault]" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# EDIT THIS LIST: the only directories published to Vercel.
# Add/remove entries to change what goes public. Order doesn't matter.
# -----------------------------------------------------------------------------
VAULT_DIRS=(
  "APMA Complex Numbers"
  "APMA Intro to Applied"
  "APMA Multivariable"
  "APMA Probability"
  "CHEM Gen Chem"
  "COMS Advanced Programming"
  "COMS Data Structures"
  "ELEN Circuit Analysis"
  "ELEN Intro to Electrical"
  "ELEN Signals and Systems"
  "ELEN Solid State Devices"
  "PHYS Elec Magn"
  "PHYS Intro Physics"
  "PHYS Waves"
  "RS Decision Analysis"
  "RS Machine Learning"
  "RS Quantum Computation"
)

# Wipe and recreate content/ so removed vault entries don't linger as stale pages.
rm -rf "$CONTENT_DIR"
mkdir -p "$CONTENT_DIR"

copied=0
for d in "${VAULT_DIRS[@]}"; do
  if [[ -d "$VAULT/$d" ]]; then
    cp -r "$VAULT/$d" "$CONTENT_DIR/"
    copied=$((copied + 1))
  else
    echo "WARN: skipping missing/empty directory '$d'" >&2
  fi
done

echo "INFO: copied $copied directory(ies) from vault into content/."

# Strip hidden Obsidian plugin/OS metadata that Quartz doesn't need and which
# would bloat the deploy (Thumbs.db, .DS_Store, saved plugin layouts, etc.).
find "$CONTENT_DIR" -type d -name ".obsidian" -prune -exec rm -rf {} + 2>/dev/null || true
find "$CONTENT_DIR" -type d -name ".trash" -prune -exec rm -rf {} + 2>/dev/null || true
find "$CONTENT_DIR" -type f \( -name "Thumbs.db" -o -name ".DS_Store" \) -delete 2>/dev/null || true

# Create a minimal home page linking to each imported directory, so the site root
# is navigable (Quartz's folder-page plugin renders each dir's index at /<dir>/).
{
  echo "---"
  echo "title: Home"
  echo "tags:"
  echo "  - index"
  echo "---"
  echo ""
  echo "# Lynn's Course Notes"
  echo ""
  echo "## Notebooks"
  echo ""
  for d in "${VAULT_DIRS[@]}"; do
    if [[ -d "$CONTENT_DIR/$d" ]]; then
      echo "- [[$d]]"
    fi
  done
  echo ""
  echo "> Auto-generated from the Obsidian vault by \`scripts/sync.sh\`."
} > "$CONTENT_DIR/index.md"

echo "INFO: wrote content/index.md hub page."
echo "INFO: sync complete. (Use 'npx quartz build' to render the site.)"