#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 01-init-default ==="

# 1.1 Run init
(cd "$WORK" && bash "$INIT_SCRIPT") > /dev/null 2>&1
[ $? -eq 0 ] && pass "1.1 init.sh exits 0" || fail "1.1 init.sh non-zero exit"

# 1.2 knowledge-base/_index.json exists and valid JSON
if [ -f "$WORK/knowledge-base/_index.json" ]; then
  pass "1.2 knowledge-base/_index.json exists"
  python3 -c "import json; json.load(open('$WORK/knowledge-base/_index.json'))" 2>/dev/null && \
    pass "1.2b valid JSON" || fail "1.2b invalid JSON"
else
  fail "1.2 knowledge-base/_index.json missing"
fi

# 1.3 experience/_index.json exists and valid JSON
if [ -f "$WORK/experience/_index.json" ]; then
  pass "1.3 experience/_index.json exists"
  python3 -c "import json; json.load(open('$WORK/experience/_index.json'))" 2>/dev/null && \
    pass "1.3b valid JSON" || fail "1.3b invalid JSON"
else
  fail "1.3 experience/_index.json missing"
fi

# 1.4 .mem-skill.config.json with engine=default
if [ -f "$WORK/.mem-skill.config.json" ]; then
  ENGINE=$(python3 -c "import json; print(json.load(open('$WORK/.mem-skill.config.json'))['engine'])")
  [ "$ENGINE" = "default" ] && pass "1.4 config engine=default" || fail "1.4 config engine=$ENGINE"
else
  fail "1.4 .mem-skill.config.json missing"
fi

# 1.5 knowledge-base schema
python3 -c "
import json, sys
d = json.load(open('$WORK/knowledge-base/_index.json'))
for k in ('lastUpdated','version','totalEntries','categories'):
    assert k in d, f'missing {k}'
assert isinstance(d['categories'], list)
print('OK')
" 2>/dev/null && pass "1.5 knowledge-base schema valid" || fail "1.5 knowledge-base schema invalid"

# 1.6 experience schema
python3 -c "
import json, sys
d = json.load(open('$WORK/experience/_index.json'))
for k in ('lastUpdated','version','skills'):
    assert k in d, f'missing {k}'
assert isinstance(d['skills'], list)
print('OK')
" 2>/dev/null && pass "1.6 experience schema valid" || fail "1.6 experience schema invalid"

# 1.7 lastUpdated is today
TODAY=$(date +%Y-%m-%d)
KB_DATE=$(python3 -c "import json; print(json.load(open('$WORK/knowledge-base/_index.json'))['lastUpdated'])")
[ "$KB_DATE" = "$TODAY" ] && pass "1.7 lastUpdated is today ($TODAY)" || fail "1.7 lastUpdated=$KB_DATE expected $TODAY"

# 1.8 No extra files
FILE_COUNT=$(find "$WORK" -type f | wc -l | tr -d ' ')
[ "$FILE_COUNT" -eq 3 ] && pass "1.8 exactly 3 files created" || fail "1.8 expected 3 files, found $FILE_COUNT"

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
