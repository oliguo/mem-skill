#!/usr/bin/env bash
# =============================================================================
# Run all example integration tests and generate reports
# Usage: bash examples/run_all_examples.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOTAL=0
PASSED=0
FAILED=0
FAILED_LIST=""

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  mem-skill — Example Integration Tests${NC}"
echo -e "${CYAN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"

# Auto-discover and run all example test scripts
for test_dir in "$SCRIPT_DIR"/[0-9]*/; do
  [ -d "$test_dir" ] || continue
  test_script="$test_dir/test.sh"
  test_name=$(basename "$test_dir")

  if [ ! -f "$test_script" ]; then
    echo -e "\n${YELLOW}⚠ $test_name: No test.sh found, skipping${NC}"
    continue
  fi

  ((TOTAL++))
  echo -e "\n${CYAN}─── $test_name ───${NC}"

  REPORT_FILE="$test_dir/test-report.md"
  START_TIME=$(date +%s)

  # Run the test, capture output
  set +e
  OUTPUT=$(bash "$test_script" "$PROJECT_DIR" 2>&1)
  EXIT_CODE=$?
  set -e

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  if [ $EXIT_CODE -eq 0 ]; then
    ((PASSED++))
    STATUS="PASSED"
    echo -e "  ${GREEN}✓ PASSED${NC} (${DURATION}s)"
  else
    ((FAILED++))
    STATUS="FAILED"
    FAILED_LIST+="  - $test_name\n"
    echo -e "  ${RED}✗ FAILED${NC} (exit $EXIT_CODE, ${DURATION}s)"
  fi

  # Generate per-scenario report
  cat > "$REPORT_FILE" <<EOF
# Test Report: $test_name

- **Date:** $(date '+%Y-%m-%d %H:%M:%S')
- **Status:** $STATUS
- **Duration:** ${DURATION}s
- **Exit Code:** $EXIT_CODE

## Output

\`\`\`
$OUTPUT
\`\`\`
EOF

  # Show condensed output on failure
  if [ $EXIT_CODE -ne 0 ]; then
    echo "$OUTPUT" | tail -10 | sed 's/^/    /'
  fi
done

# Summary
echo -e "\n${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
if [ -n "$FAILED_LIST" ]; then
  echo -e "\n${RED}Failed scenarios:${NC}"
  echo -e "$FAILED_LIST"
fi
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"

[ "$FAILED" -eq 0 ]
