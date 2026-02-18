#!/usr/bin/env bash
set -euo pipefail

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 07-topic-switch ==="

python3 -c "
import sys

def detect_topic_switch(prev_keywords, curr_keywords):
    '''Simulate Step 2: Topic Switch Detection.
    Switch if >= 40% of keywords changed (overlap < 60%).'''
    if not prev_keywords:
        return True  # fresh context
    prev_set = set(k.lower() for k in prev_keywords)
    curr_set = set(k.lower() for k in curr_keywords)
    if not curr_set:
        return False
    overlap = len(prev_set & curr_set) / max(len(prev_set), len(curr_set))
    return overlap <= 0.6

errors = 0

# 7.1 Same keywords
if not detect_topic_switch(['react', 'hooks', 'state'], ['react', 'hooks', 'state']):
    print('  ✓ 7.1 same keywords → no switch')
else:
    print('  ✗ 7.1 same keywords should NOT switch'); errors += 1

# 7.2 Totally different
if detect_topic_switch(['react', 'hooks', 'state'], ['docker', 'kubernetes', 'deploy']):
    print('  ✓ 7.2 100% different → switch')
else:
    print('  ✗ 7.2 100% different should switch'); errors += 1

# 7.3 Exactly 40% change (3 of 5 overlap = 60%, borderline)
if detect_topic_switch(['a', 'b', 'c', 'd', 'e'], ['a', 'b', 'c', 'x', 'y']):
    print('  ✓ 7.3 40% change → switch (overlap exactly 60%)')
else:
    print('  ✗ 7.3 borderline should switch'); errors += 1

# 7.4 30% change (7 of 10 overlap = 70%)
prev = ['a','b','c','d','e','f','g','h','i','j']
curr = ['a','b','c','d','e','f','g','x','y','z']
if not detect_topic_switch(prev, curr):
    print('  ✓ 7.4 30% change → no switch')
else:
    print('  ✗ 7.4 30% change should NOT switch'); errors += 1

# 7.5 Empty previous
if detect_topic_switch([], ['react', 'hooks']):
    print('  ✓ 7.5 empty previous → switch (fresh)')
else:
    print('  ✗ 7.5 empty should always switch'); errors += 1

sys.exit(errors)
"
RESULT=$?
if [ "$RESULT" -eq 0 ]; then
  PASS=5; FAIL=0
else
  FAIL=$RESULT; PASS=$((5 - FAIL))
fi
echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
