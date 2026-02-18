#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 05-experience-write ==="
TODAY=$(date +%Y-%m-%d)

# 5.1 Init
(cd "$WORK" && bash "$INIT_SCRIPT") > /dev/null 2>&1
pass "5.1 workspace initialized"

# 5.2 Write first experience entry
cat > "$WORK/experience/skill-remotion-video.md" <<EOF
## Audio sync issue at 30fps
**Date:** $TODAY
**Skill:** remotion-video
**Context:** Video rendered with 30fps had audio desync after 10s
**Solution:**
- Set composition fps to 60 instead of 30
- Use \`useCurrentFrame()\` for precise timing
**Key Files/Paths:**
- src/compositions/Main.tsx
**Keywords:** remotion, fps, audio, sync, video
EOF
[ -f "$WORK/experience/skill-remotion-video.md" ] && pass "5.2 experience file created" || fail "5.2 file not created"

# 5.3 Update experience index
python3 -c "
import json
with open('$WORK/experience/_index.json', 'r+') as f:
    d = json.load(f)
    d['skills'].append({
        'skillId': 'remotion-video',
        'file': 'skill-remotion-video.md',
        'keywords': ['remotion', 'video', 'fps', 'audio', 'render'],
        'count': 1
    })
    d['lastUpdated'] = '$TODAY'
    f.seek(0)
    json.dump(d, f, indent=2)
    f.truncate()
"
pass "5.3 experience index updated"

# 5.4 JSON valid
python3 -c "import json; json.load(open('$WORK/experience/_index.json'))" && \
  pass "5.4 _index.json still valid" || fail "5.4 _index.json broken"

# 5.5 Entry format
CONTENT=$(cat "$WORK/experience/skill-remotion-video.md")
echo "$CONTENT" | grep -q "^\*\*Date:\*\*" && pass "5.5a has Date" || fail "5.5a missing Date"
echo "$CONTENT" | grep -q "^\*\*Skill:\*\*" && pass "5.5b has Skill" || fail "5.5b missing Skill"
echo "$CONTENT" | grep -q "^\*\*Context:\*\*" && pass "5.5c has Context" || fail "5.5c missing Context"
echo "$CONTENT" | grep -q "^\*\*Solution:\*\*" && pass "5.5d has Solution" || fail "5.5d missing Solution"
echo "$CONTENT" | grep -q "^\*\*Key Files/Paths:\*\*" && pass "5.5e has Key Files" || fail "5.5e missing Key Files"
echo "$CONTENT" | grep -q "^\*\*Keywords:\*\*" && pass "5.5f has Keywords" || fail "5.5f missing Keywords"

# 5.6 Append second entry
cat >> "$WORK/experience/skill-remotion-video.md" <<EOF

## Font loading timeout
**Date:** $TODAY
**Skill:** remotion-video
**Context:** Custom fonts failed to load in Lambda rendering
**Solution:**
- Preload fonts in Root.tsx
- Use waitForFont() before render
**Key Files/Paths:**
- src/Root.tsx
**Keywords:** remotion, font, lambda, timeout
EOF

ENTRY_COUNT=$(grep -c "^## " "$WORK/experience/skill-remotion-video.md")
[ "$ENTRY_COUNT" -eq 2 ] && pass "5.6 two entries in same file ($ENTRY_COUNT)" || fail "5.6 expected 2 entries, got $ENTRY_COUNT"

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
