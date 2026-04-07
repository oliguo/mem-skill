#!/usr/bin/env bash
set -euo pipefail

# Build a distributable zip for GitHub Releases.
#
# Usage:
#   bash scripts/release.sh            # → dist/mem-skill-v1.2.0.zip
#   bash scripts/release.sh --dry-run  # list files without zipping
#
# What ships:
#   SKILL.md, README.md, LICENSE
#   references/          (engine docs)
#   scripts/init.sh      (workspace initializer)
#   knowledge-base/_index.json  (starter categories, counts zeroed)
#   experience/_index.json      (empty skills array)
#
# What does NOT ship:
#   tests/, examples/, scripts/package.sh, scripts/release.sh,
#   scripts/bump-version.sh, .venv/, node_modules/, dev entries

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# Read version from package.json
VERSION=$(python3 -c "import json; print(json.load(open('package.json'))['version'])")
ZIP_NAME="mem-skill-v${VERSION}.zip"

echo "==> Building release: $ZIP_NAME"
echo ""

# --- 1. Staging directory ---
STAGING=$(mktemp -d)
trap "rm -rf '$STAGING'" EXIT
STAGE="$STAGING/mem-skill"
mkdir -p "$STAGE"

# --- 2. Copy distributable files ---
cp SKILL.md  "$STAGE/"
cp README.md "$STAGE/"
cp LICENSE   "$STAGE/"

# references/ (engine docs)
cp -r references "$STAGE/"

# scripts/ — only init.sh (the user-facing script)
mkdir -p "$STAGE/scripts"
cp scripts/init.sh "$STAGE/scripts/"

# --- 3. Clean indexes (zero counts, no dev entries) ---
TODAY=$(date +%Y-%m-%d)

mkdir -p "$STAGE/knowledge-base"
python3 -c "
import json
with open('knowledge-base/_index.json') as f:
    d = json.load(f)
d['totalEntries'] = 0
d['lastUpdated'] = '$TODAY'
for cat in d['categories']:
    cat['count'] = 0
with open('$STAGE/knowledge-base/_index.json', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"

mkdir -p "$STAGE/experience"
python3 -c "
import json
with open('experience/_index.json') as f:
    d = json.load(f)
d['skills'] = []
d['lastUpdated'] = '$TODAY'
with open('$STAGE/experience/_index.json', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"

# --- 4. List contents ---
echo "  Contents:"
(cd "$STAGE" && find . -type f | sort | sed 's|^\./|    |')
echo ""

FILE_COUNT=$(cd "$STAGE" && find . -type f | wc -l | tr -d ' ')
echo "  $FILE_COUNT files staged"
echo ""

if $DRY_RUN; then
  echo "  (dry-run — no zip created)"
  exit 0
fi

# --- 5. Create zip ---
mkdir -p "$PROJECT_DIR/dist"
(cd "$STAGING" && zip -rq "$PROJECT_DIR/dist/$ZIP_NAME" mem-skill)

ZIP_SIZE=$(du -h "$PROJECT_DIR/dist/$ZIP_NAME" | cut -f1 | tr -d ' ')
echo "==> Created: dist/$ZIP_NAME ($ZIP_SIZE)"
echo ""
echo "  Upload to GitHub Releases:"
echo "    gh release create v${VERSION} dist/$ZIP_NAME --title \"v${VERSION}\" --notes \"Release notes here\""
echo ""
echo "  Users install by:"
echo "    1. Download & unzip to ~/.agents/skills/mem-skill/"
echo "    2. Run: /mem-skill init"
