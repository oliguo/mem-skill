#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 08-dynamic-category ==="
TODAY=$(date +%Y-%m-%d)

# 8.1 Init (init.sh creates empty categories; we start from 0)
(cd "$WORK" && bash "$INIT_SCRIPT") > /dev/null 2>&1
CAT_COUNT=$(python3 -c "import json; print(len(json.load(open('$WORK/knowledge-base/_index.json'))['categories']))")
[ "$CAT_COUNT" -eq 0 ] && pass "8.1 starts with 0 categories (fresh init)" || fail "8.1 expected 0 categories, got $CAT_COUNT"

# 8.2-8.3 Simulate dynamic category creation (no match found → create new)
python3 -c "
import json

with open('$WORK/knowledge-base/_index.json', 'r+') as f:
    d = json.load(f)
    new_cat = {
        'id': 'data-science',
        'name': 'Data Science',
        'keywords': ['pandas', 'numpy', 'ml', 'dataset', 'model'],
        'file': 'data-science.md',
        'count': 0
    }
    d['categories'].append(new_cat)
    d['lastUpdated'] = '$TODAY'
    d['totalEntries'] = sum(c['count'] for c in d['categories'])
    f.seek(0)
    json.dump(d, f, indent=2)
    f.truncate()
"
pass "8.2 new category added to _index.json"

# 8.3 Schema check
python3 -c "
import json, sys
with open('$WORK/knowledge-base/_index.json') as f:
    d = json.load(f)
cat = [c for c in d['categories'] if c['id'] == 'data-science']
if not cat:
    print('  ✗ 8.3 category not found'); sys.exit(1)
cat = cat[0]
required = {'id', 'name', 'keywords', 'file', 'count'}
if required.issubset(cat.keys()):
    print('  ✓ 8.3 new category has correct schema')
else:
    print(f'  ✗ 8.3 missing fields: {required - cat.keys()}'); sys.exit(1)
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# 8.4 Create the .md file
touch "$WORK/knowledge-base/data-science.md"
[ -f "$WORK/knowledge-base/data-science.md" ] && pass "8.4 data-science.md created" || fail "8.4 .md not created"

# 8.5 Count
CAT_COUNT=$(python3 -c "import json; print(len(json.load(open('$WORK/knowledge-base/_index.json'))['categories']))")
[ "$CAT_COUNT" -eq 1 ] && pass "8.5 now 1 category" || fail "8.5 expected 1, got $CAT_COUNT"

# 8.6 Re-match
python3 -c "
import json, sys
with open('$WORK/knowledge-base/_index.json') as f:
    d = json.load(f)
cats = d['categories']
user_kw = ['pandas', 'dataset']
matched = [c['id'] for c in cats if any(uk.lower() in [k.lower() for k in c['keywords']] for uk in user_kw)]
if 'data-science' in matched:
    print('  ✓ 8.6 re-match finds data-science')
else:
    print(f'  ✗ 8.6 re-match failed: {matched}'); sys.exit(1)
" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
