#!/usr/bin/env bash
# mem-skill clean packaging script
#
# This script creates a distributable .skill package with CLEAN indexes
# (no dev entries), while preserving our working development data.
#
# Usage: bash scripts/package.sh
#
# What it does:
#   1. Backs up current knowledge-base/ and experience/ (dev data)
#   2. Replaces them with clean templates (empty entries, count=0)
#   3. Runs the skill-creator packager
#   4. Restores the original dev data
#
# Users who install the packaged skill will get:
#   - knowledge-base/_index.json with 5 starter categories, all count=0
#   - experience/_index.json with empty skills array
#   - NO .md content files (clean slate)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "==> Packaging mem-skill (clean distribution)"
echo ""

# --- 1. Create a clean staging directory with only shipped files ---
echo "  1. Creating clean staging directory..."
STAGING=$(mktemp -d)
trap "rm -rf '$STAGING'" EXIT
STAGE_DIR="$STAGING/mem-skill"
mkdir -p "$STAGE_DIR"

# Copy only what should ship (matches package.json "files" array)
cp "$PROJECT_DIR/SKILL.md" "$STAGE_DIR/"
cp "$PROJECT_DIR/package.json" "$STAGE_DIR/"
cp "$PROJECT_DIR/LICENSE" "$STAGE_DIR/" 2>/dev/null || true
cp "$PROJECT_DIR/README.md" "$STAGE_DIR/" 2>/dev/null || true
cp -r "$PROJECT_DIR/references" "$STAGE_DIR/"
cp -r "$PROJECT_DIR/scripts" "$STAGE_DIR/"

# Copy knowledge-base and experience with CLEAN state
mkdir -p "$STAGE_DIR/knowledge-base" "$STAGE_DIR/experience"

# --- 2. Write clean indexes (no dev entries) ---
echo "  2. Writing clean indexes..."
TODAY=$(date +%Y-%m-%d)

python3 -c "
import json
with open('$PROJECT_DIR/knowledge-base/_index.json') as f:
    d = json.load(f)
d['totalEntries'] = 0
d['lastUpdated'] = '$TODAY'
for cat in d['categories']:
    cat['count'] = 0
with open('$STAGE_DIR/knowledge-base/_index.json', 'w') as f:
    json.dump(d, f, indent=2)
print('     ✓ knowledge-base/_index.json (all counts reset to 0)')
"

python3 -c "
import json
with open('$PROJECT_DIR/experience/_index.json') as f:
    d = json.load(f)
d['skills'] = []
d['lastUpdated'] = '$TODAY'
with open('$STAGE_DIR/experience/_index.json', 'w') as f:
    json.dump(d, f, indent=2)
print('     ✓ experience/_index.json (empty skills array)')
"

# Remove package.sh itself from staged scripts (users don't need it)
rm -f "$STAGE_DIR/scripts/package.sh"

echo "  3. Staged files:"
find "$STAGE_DIR" -type f | sed "s|$STAGE_DIR/|     |"

# --- 4. Package ---
echo "  4. Running packager..."
PACKAGER="$HOME/.agents/skills/skill-creator/scripts/package_skill.py"
PKG_EXIT=0
if [ -f "$PACKAGER" ]; then
  # Use project venv python if available (has pyyaml), else system python
  PYTHON="python3"
  if [ -f "$PROJECT_DIR/.venv/bin/python" ]; then
    PYTHON="$PROJECT_DIR/.venv/bin/python"
  fi
  # Package the clean staging directory, output to project root
  $PYTHON "$PACKAGER" "$STAGE_DIR" "$PROJECT_DIR" || PKG_EXIT=$?
  if [ $PKG_EXIT -eq 0 ]; then
    echo "     ✓ Package created"
  else
    echo "     ✗ Packager failed (exit $PKG_EXIT)"
  fi
else
  echo "     ⚠ skill-creator packager not found at: $PACKAGER"
  echo "     You can manually zip the files listed in package.json"
  PKG_EXIT=1
fi

# Staging dir cleaned up automatically via EXIT trap

echo ""
if [ $PKG_EXIT -eq 0 ]; then
  echo "==> Done! Package is ready for distribution."
else
  echo "==> Packaging failed."
fi
echo "    Dev knowledge-base and experience are UNTOUCHED."
echo ""
echo "    Shipped content:"
echo "      knowledge-base/_index.json  → 5 categories, all count=0"
echo "      experience/_index.json      → empty skills array"
echo "      *.md content files          → NONE"
exit $PKG_EXIT
