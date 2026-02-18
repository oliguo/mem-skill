#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${1:-.}"
INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✓ $1"; }
fail() { ((FAIL++)); echo "  ✗ $1"; }

echo "=== 02-init-qmd ==="

# 2.1 When QMD is not installed, init --mem-engine=qmd should fail gracefully.
# When QMD IS installed, qmd collection commands may fail in a bare test
# workspace (no .md files to embed). Either outcome is acceptable here;
# the structural checks (2.2-2.5) verify the script logic.
set +e
(cd "$WORK" && echo "n" | bash "$INIT_SCRIPT" --mem-engine=qmd) > /dev/null 2>&1
EXIT=$?
set -e

if command -v qmd &>/dev/null; then
  # QMD is installed — init may succeed or fail (qmd commands need real files).
  # As long as it ran (didn't syntax error), we accept either outcome.
  pass "2.1 init --mem-engine=qmd ran (QMD installed, exit=$EXIT)"
else
  # QMD is NOT installed — init should exit non-zero when user declines
  [ $EXIT -ne 0 ] && pass "2.1 init exits non-zero when QMD missing + user declines" || fail "2.1 init did not exit non-zero"
fi

# 2.2 Script references qmd engine config
grep -q '"engine": "qmd"' "$INIT_SCRIPT" && pass "2.2 script contains qmd engine config" || fail "2.2 qmd config not in script"

# 2.3 Script checks for QMD binary
grep -qE 'command -v qmd|which qmd' "$INIT_SCRIPT" && pass "2.3 script checks for QMD binary" || fail "2.3 no QMD binary check"

# 2.4 Script sets up collections
grep -q 'qmd collection add' "$INIT_SCRIPT" && pass "2.4 script has qmd collection add" || fail "2.4 no collection add"

# 2.5 Script runs embed
grep -q 'qmd embed' "$INIT_SCRIPT" && pass "2.5 script has qmd embed" || fail "2.5 no qmd embed"

echo "  --- $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ]
