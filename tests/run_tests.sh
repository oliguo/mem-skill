#!/usr/bin/env bash
# =============================================================================
# mem-skill test suite
# Run: bash tests/run_tests.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0
WARN=0
ERRORS=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { ((PASS++)); echo -e "  ${GREEN}✓${NC} $1"; }
fail() { ((FAIL++)); ERRORS+="  FAIL: $1\n"; echo -e "  ${RED}✗${NC} $1"; }
warn() { ((WARN++)); echo -e "  ${YELLOW}⚠${NC} $1"; }
section() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

# =============================================================================
section "1. Structure & Required Files"
# =============================================================================

REQUIRED_FILES=(
  "SKILL.md"
  "knowledge-base/_index.json"
  "experience/_index.json"
  "references/qmd-engine.md"
  "references/engines.md"
  "scripts/init.sh"
  "package.json"
  "README.md"
  "LICENSE"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    pass "$f exists"
  else
    fail "$f is MISSING"
  fi
done

# No extraneous docs (skill-creator says no README in skill package, but we keep
# README.md for GitHub repo — just check against bad extras)
BAD_FILES=("INSTALLATION_GUIDE.md" "QUICK_REFERENCE.md" "CHANGELOG.md")
for f in "${BAD_FILES[@]}"; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    warn "$f exists — skill-creator recommends against auxiliary docs in skill package"
  else
    pass "No extraneous $f"
  fi
done

# =============================================================================
section "2. SKILL.md Frontmatter Validation"
# =============================================================================

# Check frontmatter starts with ---
if head -1 "$PROJECT_DIR/SKILL.md" | grep -q "^---$"; then
  pass "SKILL.md starts with YAML frontmatter delimiter"
else
  fail "SKILL.md missing frontmatter opening ---"
fi

# Extract frontmatter (macOS-compatible: sed instead of head -n -1)
FRONTMATTER=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1{print} found==2{exit}' "$PROJECT_DIR/SKILL.md")

# Check 'name' field
if echo "$FRONTMATTER" | grep -q "^name:"; then
  SKILL_NAME=$(echo "$FRONTMATTER" | grep "^name:" | sed 's/name: *//')
  if echo "$SKILL_NAME" | grep -qE '^[a-z0-9-]+$'; then
    pass "name is hyphen-case: $SKILL_NAME"
  else
    fail "name is not hyphen-case: $SKILL_NAME"
  fi
else
  fail "Missing 'name' in frontmatter"
fi

# Check 'description' field
if echo "$FRONTMATTER" | grep -q "^description:"; then
  pass "description field present"
else
  fail "Missing 'description' in frontmatter"
fi

# Check no angle brackets in description
DESC_LINE=$(sed -n '3p' "$PROJECT_DIR/SKILL.md")
if echo "$DESC_LINE" | grep -q '[<>]'; then
  fail "Description contains angle brackets (< or >) — forbidden by validator"
else
  pass "Description has no angle brackets"
fi

# Check description length <= 1024
DESC_LEN=${#DESC_LINE}
if [ "$DESC_LEN" -le 1024 ]; then
  pass "Description length ($DESC_LEN chars) <= 1024 max"
else
  fail "Description too long ($DESC_LEN chars > 1024)"
fi

# Check no forbidden frontmatter keys (only name, description, license, allowed-tools, metadata)
FORBIDDEN_KEYS=$(echo "$FRONTMATTER" | grep -E '^[a-z]' | sed 's/:.*//' | grep -vE '^(name|description|license|allowed-tools|metadata)$' || true)
if [ -z "$FORBIDDEN_KEYS" ]; then
  pass "No unexpected frontmatter keys"
else
  fail "Unexpected frontmatter keys: $FORBIDDEN_KEYS"
fi

# =============================================================================
section "3. SKILL.md Body Quality"
# =============================================================================

SKILL_LINES=$(wc -l < "$PROJECT_DIR/SKILL.md")
if [ "$SKILL_LINES" -le 500 ]; then
  pass "SKILL.md body is $SKILL_LINES lines (<= 500 recommended max)"
else
  warn "SKILL.md body is $SKILL_LINES lines (> 500 recommended max — consider splitting to references)"
fi

# Check that references are mentioned in SKILL.md
if grep -q "references/qmd-engine.md" "$PROJECT_DIR/SKILL.md"; then
  pass "SKILL.md references qmd-engine.md"
else
  fail "SKILL.md does not reference qmd-engine.md (progressive disclosure needs links)"
fi

if grep -q "references/engines.md" "$PROJECT_DIR/SKILL.md"; then
  pass "SKILL.md references engines.md"
else
  fail "SKILL.md does not reference engines.md"
fi

# Check core loop sections exist
for keyword in "Step 1:" "Step 2:" "Step 3:" "Step 4:" "Step 5:"; do
  if grep -q "$keyword" "$PROJECT_DIR/SKILL.md"; then
    pass "Core loop $keyword found"
  else
    fail "Core loop $keyword missing from SKILL.md"
  fi
done

# Check init command documented
if grep -q "/mem-skill init" "$PROJECT_DIR/SKILL.md"; then
  pass "Init command documented"
else
  fail "Init command '/mem-skill init' not documented"
fi

# Check --mem-engine=qmd documented
if grep -q "\-\-mem-engine=qmd" "$PROJECT_DIR/SKILL.md"; then
  pass "--mem-engine=qmd option documented"
else
  fail "--mem-engine=qmd option not documented"
fi

# =============================================================================
section "4. JSON Index Integrity"
# =============================================================================

# Validate JSON syntax
for jf in "knowledge-base/_index.json" "experience/_index.json"; do
  if python3 -c "import json; json.load(open('$PROJECT_DIR/$jf'))" 2>/dev/null; then
    pass "$jf is valid JSON"
  else
    fail "$jf is INVALID JSON"
  fi
done

# Validate knowledge-base index schema
python3 -c "
import json, sys
with open('$PROJECT_DIR/knowledge-base/_index.json') as f:
    d = json.load(f)
required = {'lastUpdated','version','totalEntries','categories'}
missing = required - set(d.keys())
if missing:
    print(f'FAIL: knowledge-base/_index.json missing keys: {missing}')
    sys.exit(1)
if not isinstance(d['categories'], list):
    print('FAIL: categories is not a list')
    sys.exit(1)
for cat in d['categories']:
    for k in ('id','name','keywords','file','count'):
        if k not in cat:
            print(f'FAIL: category missing key: {k} in {cat}')
            sys.exit(1)
    if not isinstance(cat['keywords'], list):
        print(f'FAIL: keywords is not a list in category {cat[\"id\"]}')
        sys.exit(1)
print('OK')
" && pass "knowledge-base/_index.json schema valid" || fail "knowledge-base/_index.json schema invalid"

# Validate experience index schema
python3 -c "
import json, sys
with open('$PROJECT_DIR/experience/_index.json') as f:
    d = json.load(f)
required = {'lastUpdated','version','skills'}
missing = required - set(d.keys())
if missing:
    print(f'FAIL: experience/_index.json missing keys: {missing}')
    sys.exit(1)
if not isinstance(d['skills'], list):
    print('FAIL: skills is not a list')
    sys.exit(1)
print('OK')
" && pass "experience/_index.json schema valid" || fail "experience/_index.json schema invalid"

# =============================================================================
section "5. Init Script Validation"
# =============================================================================

INIT_SCRIPT="$PROJECT_DIR/scripts/init.sh"

# Is executable
if [ -x "$INIT_SCRIPT" ]; then
  pass "scripts/init.sh is executable"
else
  fail "scripts/init.sh is not executable"
fi

# Shebang
if head -1 "$INIT_SCRIPT" | grep -q "^#!/"; then
  pass "scripts/init.sh has shebang"
else
  fail "scripts/init.sh missing shebang"
fi

# Supports --help
if grep -q "\-\-help" "$INIT_SCRIPT"; then
  pass "scripts/init.sh supports --help"
else
  warn "scripts/init.sh doesn't mention --help"
fi

# Handles --mem-engine= flag
if grep -q "\-\-mem-engine=" "$INIT_SCRIPT"; then
  pass "scripts/init.sh handles --mem-engine flag"
else
  fail "scripts/init.sh doesn't handle --mem-engine flag"
fi

# Creates directories
if grep -q "mkdir" "$INIT_SCRIPT"; then
  pass "scripts/init.sh creates directories"
else
  fail "scripts/init.sh doesn't create directories"
fi

# Writes config file
if grep -q ".mem-skill.config.json" "$INIT_SCRIPT"; then
  pass "scripts/init.sh writes .mem-skill.config.json"
else
  fail "scripts/init.sh doesn't write .mem-skill.config.json"
fi

# Dry-run init in a temp directory (default engine)
TMPDIR=$(mktemp -d)
(cd "$TMPDIR" && bash "$INIT_SCRIPT" 2>&1) > /dev/null
if [ -f "$TMPDIR/knowledge-base/_index.json" ] && [ -f "$TMPDIR/experience/_index.json" ] && [ -f "$TMPDIR/.mem-skill.config.json" ]; then
  pass "Dry-run init (default engine) created all expected files"
  # Verify generated config
  ENGINE=$(python3 -c "import json; print(json.load(open('$TMPDIR/.mem-skill.config.json'))['engine'])")
  if [ "$ENGINE" = "default" ]; then
    pass "Generated config has engine=default"
  else
    fail "Generated config engine=$ENGINE (expected 'default')"
  fi
  # Verify generated JSON indexes are valid
  python3 -c "import json; json.load(open('$TMPDIR/knowledge-base/_index.json'))" 2>/dev/null && \
    pass "Dry-run knowledge-base/_index.json is valid JSON" || \
    fail "Dry-run knowledge-base/_index.json is invalid JSON"
  python3 -c "import json; json.load(open('$TMPDIR/experience/_index.json'))" 2>/dev/null && \
    pass "Dry-run experience/_index.json is valid JSON" || \
    fail "Dry-run experience/_index.json is invalid JSON"
else
  fail "Dry-run init (default engine) failed to create expected files"
  echo "    Contents of $TMPDIR:"
  ls -laR "$TMPDIR" 2>/dev/null || true
fi
rm -rf "$TMPDIR"

# Idempotency: running init twice should not error
TMPDIR2=$(mktemp -d)
(cd "$TMPDIR2" && bash "$INIT_SCRIPT" 2>&1 && bash "$INIT_SCRIPT" 2>&1) > /dev/null
if [ $? -eq 0 ]; then
  pass "Init script is idempotent (runs twice without error)"
else
  fail "Init script fails on second run (not idempotent)"
fi
rm -rf "$TMPDIR2"

# =============================================================================
section "6. Package.json Validation"
# =============================================================================

python3 -c "
import json, sys
with open('$PROJECT_DIR/package.json') as f:
    pkg = json.load(f)
errors = []
if pkg.get('name') != 'mem-skill':
    errors.append(f'name should be mem-skill, got {pkg.get(\"name\")}')
if 'version' not in pkg:
    errors.append('missing version')
if 'description' not in pkg:
    errors.append('missing description')
if 'license' not in pkg:
    errors.append('missing license')
if 'keywords' not in pkg or not isinstance(pkg['keywords'], list):
    errors.append('missing or invalid keywords')
if 'files' not in pkg or not isinstance(pkg['files'], list):
    errors.append('missing files array')
else:
    for req in ['SKILL.md', 'knowledge-base/', 'experience/', 'references/', 'scripts/']:
        if req not in pkg['files']:
            errors.append(f'{req} not in files array')
if errors:
    for e in errors:
        print(f'FAIL: {e}')
    sys.exit(1)
print('OK')
" && pass "package.json schema valid" || fail "package.json schema invalid"

# =============================================================================
section "7. Security Checks"
# =============================================================================

# No secrets or tokens in any file
SECRETS_PATTERN='(password|secret|token|api_key|API_KEY|private_key|aws_access|GITHUB_TOKEN)\s*[:=]'
if grep -rIE "$SECRETS_PATTERN" "$PROJECT_DIR" --include='*.md' --include='*.json' --include='*.sh' --include='*.py' --exclude-dir='.venv' --exclude-dir='.git' --exclude-dir='node_modules' --exclude-dir='tests' --exclude-dir='examples' 2>/dev/null | head -5; then
  fail "Potential secrets/tokens found in files"
else
  pass "No hardcoded secrets or tokens detected"
fi

# No eval or dangerous patterns in shell scripts
if grep -rE '(eval |`.*\$|rm -rf /[^.]|curl.*\| *sh|wget.*\| *sh)' "$PROJECT_DIR/scripts/" 2>/dev/null; then
  fail "Potentially dangerous shell patterns found in scripts"
else
  pass "No dangerous shell patterns (eval, pipe-to-sh, rm -rf /)"
fi

# Shell scripts use set -euo pipefail
for sh in "$PROJECT_DIR"/scripts/*.sh; do
  if [ -f "$sh" ]; then
    if grep -q "set -euo pipefail" "$sh"; then
      pass "$(basename "$sh") uses strict error handling (set -euo pipefail)"
    else
      warn "$(basename "$sh") missing 'set -euo pipefail'"
    fi
  fi
done

# Check no .env or sensitive files
SENSITIVE_FILES=(".env" ".env.local" ".npmrc" "id_rsa" "id_ed25519")
for sf in "${SENSITIVE_FILES[@]}"; do
  if [ -f "$PROJECT_DIR/$sf" ]; then
    fail "Sensitive file found: $sf"
  else
    pass "No sensitive file: $sf"
  fi
done

# =============================================================================
section "8. Cross-Reference Integrity"
# =============================================================================

# All files referenced in SKILL.md should exist
python3 -c "
import re, os, sys
with open('$PROJECT_DIR/SKILL.md') as f:
    content = f.read()
# Match markdown links like [text](references/foo.md)
links = re.findall(r'\[.*?\]\((references/[^\)]+|scripts/[^\)]+)\)', content)
errors = []
for link in links:
    path = os.path.join('$PROJECT_DIR', link)
    if not os.path.exists(path):
        errors.append(f'Broken link: {link}')
if errors:
    for e in errors:
        print(f'FAIL: {e}')
    sys.exit(1)
print(f'OK: {len(links)} internal links verified')
" && pass "All SKILL.md internal links resolve" || fail "SKILL.md has broken internal links"

# Knowledge base categories all have valid file references
python3 -c "
import json, sys
with open('$PROJECT_DIR/knowledge-base/_index.json') as f:
    d = json.load(f)
errors = []
for cat in d['categories']:
    if not cat.get('file','').endswith('.md'):
        errors.append(f'Category {cat[\"id\"]} file does not end with .md: {cat.get(\"file\")}')
    if not cat.get('id'):
        errors.append(f'Category missing id')
    if not cat.get('keywords') or len(cat['keywords']) == 0:
        errors.append(f'Category {cat[\"id\"]} has no keywords')
if errors:
    for e in errors:
        print(f'FAIL: {e}')
    sys.exit(1)
print('OK')
" && pass "Knowledge base categories have valid schema" || fail "Knowledge base categories schema invalid"

# =============================================================================
section "9. Official Validator (skill-creator)"
# =============================================================================

VALIDATOR="/Users/oli/.agents/skills/skill-creator/scripts/quick_validate.py"
if [ -f "$VALIDATOR" ]; then
  RESULT=$(/Users/oli/Documents/Github/Personal/mem-skill/.venv/bin/python "$VALIDATOR" "$PROJECT_DIR" 2>&1)
  if echo "$RESULT" | grep -q "valid"; then
    pass "Official skill-creator validator: $RESULT"
  else
    fail "Official skill-creator validator: $RESULT"
  fi
else
  warn "skill-creator validator not found at $VALIDATOR"
fi

# =============================================================================
# Summary
# =============================================================================
echo -e "\n${CYAN}━━━ TEST SUMMARY ━━━${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
echo -e "  ${YELLOW}Warnings: $WARN${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}Failures:${NC}"
  echo -e "$ERRORS"
  exit 1
else
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
fi
