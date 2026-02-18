#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 03-init-idempotent ==="

# 3.1 First init
(cd "$WORK" && bash "$INIT_SCRIPT") > /dev/null 2>&1
[ $? -eq 0 ] && pass "3.1 first init succeeds" || fail "3.1 first init failed"

# 3.2 Add custom content
echo "## My custom knowledge entry" > "$WORK/knowledge-base/my-custom.md"
pass "3.2 custom content added"

# Save original index date
ORIG_DATE=$(python3 -c "import json; print(json.load(open('$WORK/knowledge-base/_index.json'))['lastUpdated'])")

# 3.3 Second init
(cd "$WORK" && bash "$INIT_SCRIPT") > /dev/null 2>&1
[ $? -eq 0 ] && pass "3.3 second init succeeds" || fail "3.3 second init failed"

# 3.4 Custom content preserved
if [ -f "$WORK/knowledge-base/my-custom.md" ]; then
  CONTENT=$(cat "$WORK/knowledge-base/my-custom.md")
  [ "$CONTENT" = "## My custom knowledge entry" ] && pass "3.4 custom content preserved" || fail "3.4 custom content changed"
else
  fail "3.4 custom content file deleted"
fi

# 3.5 Index not overwritten
NEW_DATE=$(python3 -c "import json; print(json.load(open('$WORK/knowledge-base/_index.json'))['lastUpdated'])")
[ "$NEW_DATE" = "$ORIG_DATE" ] && pass "3.5 _index.json not overwritten (date preserved)" || fail "3.5 _index.json was overwritten"

# 3.6 Config refreshed
[ -f "$WORK/.mem-skill.config.json" ] && pass "3.6 config exists after second init" || fail "3.6 config missing"

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
