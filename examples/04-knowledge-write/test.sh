#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 04-knowledge-write ==="

# 4.1 Init
(cd "$WORK" && bash "$INIT_SCRIPT") > /dev/null 2>&1
pass "4.1 workspace initialized"

# 4.2 Write a knowledge entry
TODAY=$(date +%Y-%m-%d)
cat > "$WORK/knowledge-base/devops.md" <<EOF
## Use Docker Multi-Stage Builds
**Date:** $TODAY
**Context:** Reducing Docker image size for production deployments
**Best Practice:**
- Use multi-stage builds to separate build and runtime dependencies
- Pin base image versions for reproducibility
**Keywords:** docker, multi-stage, build, image, production
EOF
[ -f "$WORK/knowledge-base/devops.md" ] && pass "4.2 devops.md created" || fail "4.2 devops.md not created"

# 4.3 Update _index.json
python3 -c "
import json
with open('$WORK/knowledge-base/_index.json', 'r+') as f:
    d = json.load(f)
    d['categories'].append({
        'id': 'devops',
        'name': 'DevOps',
        'keywords': ['docker', 'kubernetes', 'CI/CD', 'deploy', 'container'],
        'file': 'devops.md',
        'count': 1
    })
    d['totalEntries'] = sum(c['count'] for c in d['categories'])
    d['lastUpdated'] = '$TODAY'
    f.seek(0)
    json.dump(d, f, indent=2)
    f.truncate()
"
pass "4.3 _index.json updated with devops category"

# 4.4 JSON still valid
python3 -c "import json; json.load(open('$WORK/knowledge-base/_index.json'))" && \
  pass "4.4 _index.json still valid JSON" || fail "4.4 _index.json broken"

# 4.5 totalEntries
TOTAL=$(python3 -c "import json; print(json.load(open('$WORK/knowledge-base/_index.json'))['totalEntries'])")
[ "$TOTAL" = "1" ] && pass "4.5 totalEntries=1" || fail "4.5 totalEntries=$TOTAL expected 1"

# 4.6 lastUpdated
UPDATED=$(python3 -c "import json; print(json.load(open('$WORK/knowledge-base/_index.json'))['lastUpdated'])")
[ "$UPDATED" = "$TODAY" ] && pass "4.6 lastUpdated=$TODAY" || fail "4.6 lastUpdated=$UPDATED"

# 4.7 Entry format
CONTENT=$(cat "$WORK/knowledge-base/devops.md")
echo "$CONTENT" | grep -q "^\*\*Date:\*\*" && pass "4.7a has Date field" || fail "4.7a missing Date"
echo "$CONTENT" | grep -q "^\*\*Context:\*\*" && pass "4.7b has Context field" || fail "4.7b missing Context"
echo "$CONTENT" | grep -q "^\*\*Best Practice:\*\*" && pass "4.7c has Best Practice field" || fail "4.7c missing Best Practice"
echo "$CONTENT" | grep -q "^\*\*Keywords:\*\*" && pass "4.7d has Keywords field" || fail "4.7d missing Keywords"

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
