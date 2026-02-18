#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 09-version-bump ==="

# Work on a copy of package.json
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT
cp "$PROJECT_DIR/package.json" "$WORK/package.json"

# Force starting version to 1.0.0 for deterministic testing
python3 -c "
import json
with open('$WORK/package.json', 'r+') as f:
    d = json.load(f)
    d['version'] = '1.0.0'
    f.seek(0)
    json.dump(d, f, indent=2)
    f.truncate()
"

# 9.1 Read version
VER=$(python3 -c "import json; print(json.load(open('$WORK/package.json'))['version'])")
echo "$VER" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' && pass "9.1 current version=$VER" || fail "9.1 invalid version=$VER"

# Helper: bump version
bump() {
  local TYPE=$1 FILE=$2
  python3 -c "
import json
with open('$FILE', 'r+') as f:
    d = json.load(f)
    parts = list(map(int, d['version'].split('.')))
    if '$TYPE' == 'patch': parts[2] += 1
    elif '$TYPE' == 'minor': parts[1] += 1; parts[2] = 0
    elif '$TYPE' == 'major': parts[0] += 1; parts[1] = 0; parts[2] = 0
    d['version'] = '.'.join(map(str, parts))
    f.seek(0)
    json.dump(d, f, indent=2)
    f.truncate()
"
}

# 9.2 Patch bump
bump patch "$WORK/package.json"
NEW=$(python3 -c "import json; print(json.load(open('$WORK/package.json'))['version'])")
[ "$NEW" = "1.0.1" ] && pass "9.2 patch → $NEW" || fail "9.2 expected 1.0.1, got $NEW"

# 9.3 Minor bump
bump minor "$WORK/package.json"
NEW=$(python3 -c "import json; print(json.load(open('$WORK/package.json'))['version'])")
[ "$NEW" = "1.1.0" ] && pass "9.3 minor → $NEW" || fail "9.3 expected 1.1.0, got $NEW"

# 9.4 Major bump
bump major "$WORK/package.json"
NEW=$(python3 -c "import json; print(json.load(open('$WORK/package.json'))['version'])")
[ "$NEW" = "2.0.0" ] && pass "9.4 major → $NEW" || fail "9.4 expected 2.0.0, got $NEW"

# 9.5 JSON valid
python3 -c "import json; json.load(open('$WORK/package.json'))" && \
  pass "9.5 package.json still valid" || fail "9.5 package.json broken"

# 9.6 Semver regex
echo "$NEW" | grep -qE '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && \
  pass "9.6 semver format valid" || fail "9.6 not valid semver"

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
