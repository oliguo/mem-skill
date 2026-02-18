#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 06-keyword-matching ==="

# Use the project's real knowledge-base/_index.json
INDEX="$PROJECT_DIR/knowledge-base/_index.json"

python3 -c "
import json, sys

with open('$INDEX') as f:
    index = json.load(f)

cats = index['categories']

def match_keywords(user_keywords):
    matched = []
    user_lower = [k.lower() for k in user_keywords]
    for cat in cats:
        cat_lower = [k.lower() for k in cat['keywords']]
        if any(uk in cat_lower for uk in user_lower):
            matched.append(cat['id'])
    return matched

errors = 0

# 6.1
result = match_keywords(['React', 'CSS', 'component'])
if 'frontend-dev' in result:
    print('  ✓ 6.1 frontend keywords match frontend-dev')
else:
    print(f'  ✗ 6.1 expected frontend-dev, got {result}'); errors += 1

# 6.2
result = match_keywords(['API', 'Node.js', 'server'])
if 'backend-dev' in result:
    print('  ✓ 6.2 backend keywords match backend-dev')
else:
    print(f'  ✗ 6.2 expected backend-dev, got {result}'); errors += 1

# 6.3
result = match_keywords(['React', 'API'])
if 'frontend-dev' in result and 'backend-dev' in result:
    print('  ✓ 6.3 multi-category match works')
else:
    print(f'  ✗ 6.3 expected both, got {result}'); errors += 1

# 6.4
result = match_keywords(['quantum', 'physics', 'relativity'])
if len(result) == 0:
    print('  ✓ 6.4 unrelated keywords return empty')
else:
    print(f'  ✗ 6.4 expected empty, got {result}'); errors += 1

# 6.5
result = match_keywords(['react', 'css'])
if 'frontend-dev' in result:
    print('  ✓ 6.5 case-insensitive match works')
else:
    print(f'  ✗ 6.5 case-insensitive failed, got {result}'); errors += 1

# 6.6
result = match_keywords(['Java'])
java_in_index = any('Java' in cat['keywords'] for cat in cats)
if java_in_index:
    print('  ✓ 6.6 Java is a literal keyword — match correct')
else:
    if len(result) == 0:
        print('  ✓ 6.6 Java does not false-match JavaScript')
    else:
        print(f'  ✗ 6.6 Java false-matched: {result}'); errors += 1

sys.exit(errors)
"
