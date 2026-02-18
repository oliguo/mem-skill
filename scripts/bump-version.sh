#!/usr/bin/env bash
# mem-skill version bump utility
# Usage: bash scripts/bump-version.sh [patch|minor|major]
#
# Bumps the version in:
#   - package.json
#   - knowledge-base/_index.json  (if exists)
#   - .mem-skill.config.json      (if exists)
#
# Defaults to "patch" if no argument given.

set -euo pipefail

BUMP_TYPE="${1:-patch}"

if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
  echo "Usage: bash scripts/bump-version.sh [patch|minor|major]"
  echo "  patch  — 1.0.0 → 1.0.1  (bug fixes, doc tweaks)"
  echo "  minor  — 1.0.0 → 1.1.0  (new features, categories)"
  echo "  major  — 1.0.0 → 2.0.0  (breaking changes)"
  exit 1
fi

# Resolve project root (script is in scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Read current version from package.json
PKG="$PROJECT_DIR/package.json"
if [ ! -f "$PKG" ]; then
  echo "Error: package.json not found at $PKG"
  exit 1
fi

OLD_VER=$(python3 -c "import json; print(json.load(open('$PKG'))['version'])")

# Calculate new version
NEW_VER=$(python3 -c "
parts = list(map(int, '$OLD_VER'.split('.')))
if '$BUMP_TYPE' == 'patch':
    parts[2] += 1
elif '$BUMP_TYPE' == 'minor':
    parts[1] += 1; parts[2] = 0
elif '$BUMP_TYPE' == 'major':
    parts[0] += 1; parts[1] = 0; parts[2] = 0
print('.'.join(map(str, parts)))
")

echo "Bumping version: $OLD_VER → $NEW_VER ($BUMP_TYPE)"

# 1. Update package.json
python3 -c "
import json
with open('$PKG', 'r+') as f:
    d = json.load(f)
    d['version'] = '$NEW_VER'
    f.seek(0)
    json.dump(d, f, indent=2)
    f.truncate()
"
echo "  ✓ package.json"

# 2. Update knowledge-base/_index.json (if it has a version field)
KB_INDEX="$PROJECT_DIR/knowledge-base/_index.json"
if [ -f "$KB_INDEX" ]; then
  python3 -c "
import json
with open('$KB_INDEX', 'r+') as f:
    d = json.load(f)
    if 'version' in d:
        d['version'] = '$NEW_VER'
        f.seek(0)
        json.dump(d, f, indent=2)
        f.truncate()
        print('  ✓ knowledge-base/_index.json')
    else:
        print('  — knowledge-base/_index.json (no version field, skipped)')
"
fi

# 3. Update .mem-skill.config.json (if it exists)
CONFIG="$PROJECT_DIR/.mem-skill.config.json"
if [ -f "$CONFIG" ]; then
  python3 -c "
import json
with open('$CONFIG', 'r+') as f:
    d = json.load(f)
    if 'version' in d:
        d['version'] = '$NEW_VER'
        f.seek(0)
        json.dump(d, f, indent=2)
        f.truncate()
        print('  ✓ .mem-skill.config.json')
    else:
        print('  — .mem-skill.config.json (no version field, skipped)')
"
fi

echo ""
echo "Done! Version is now $NEW_VER"
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m 'chore: bump version to $NEW_VER'"
echo "  git tag v$NEW_VER"
