#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 10-security-scan ==="

SCAN_DIRS="$PROJECT_DIR/SKILL.md $PROJECT_DIR/scripts/ $PROJECT_DIR/references/ $PROJECT_DIR/knowledge-base/ $PROJECT_DIR/experience/"

# 10.1 No API keys
if ! grep -rE '(api[_-]?key|apikey)\s*[:=]\s*["\x27][A-Za-z0-9]{16,}' $SCAN_DIRS 2>/dev/null; then
  pass "10.1 no hardcoded API keys"
else
  fail "10.1 found API key patterns"
fi

# 10.2 No passwords
if ! grep -riE '(password|passwd|secret)\s*[:=]\s*["\x27]' $SCAN_DIRS 2>/dev/null; then
  pass "10.2 no passwords"
else
  fail "10.2 found password patterns"
fi

# 10.3 No private keys
if ! grep -rE 'BEGIN.*(PRIVATE|RSA|DSA|EC) KEY' $SCAN_DIRS 2>/dev/null; then
  pass "10.3 no private keys"
else
  fail "10.3 found private key"
fi

# 10.4 No hardcoded IPs
if ! grep -rE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' $SCAN_DIRS 2>/dev/null | grep -vE '(0\.0\.0\.0|127\.0\.0\.1|localhost)'; then
  pass "10.4 no hardcoded IPs"
else
  fail "10.4 found hardcoded IPs"
fi

# 10.5 No eval/exec in scripts
if ! grep -rE '\b(eval|exec)\s*\(' "$PROJECT_DIR/scripts/" 2>/dev/null; then
  pass "10.5 no eval/exec in scripts"
else
  fail "10.5 found eval/exec"
fi

# 10.6 No .env files
if [ ! -f "$PROJECT_DIR/.env" ]; then
  pass "10.6 no .env file"
else
  fail "10.6 .env file exists in project"
fi

# 10.7 No install hooks
if ! python3 -c "
import json, sys
with open('$PROJECT_DIR/package.json') as f:
    d = json.load(f)
scripts = d.get('scripts', {})
dangerous = [k for k in scripts if k in ('preinstall','postinstall','preuninstall','postuninstall')]
if dangerous:
    print(f'Found hooks: {dangerous}')
    sys.exit(1)
"; then
  fail "10.7 found install hooks"
else
  pass "10.7 no install hooks"
fi

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
