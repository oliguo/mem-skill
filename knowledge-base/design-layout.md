## Test-Driven Skill Development Pattern
**Date:** 2026-02-19
**Context:** Building a comprehensive skill requires both structural validation (unit tests) and real-world simulation (integration examples). The two-layer testing approach catches different classes of bugs.
**Best Practice:**
- Layer 1: `tests/run_tests.sh` — structural checks (files exist, JSON valid, YAML frontmatter correct, security scan)
- Layer 2: `examples/*/test.sh` — integration scenarios simulating real user workflows
- Each example gets its own directory: TEST_PLAN.md (table of test cases) + test.sh (executable)
- Use `mktemp -d` with trap cleanup for isolated test workspaces
- Master runner (`run_all_examples.sh`) generates per-scenario reports
- Run tests after every change; auto-fix patterns save time
**Keywords:** testing, integration, shell, test-plan, examples, validation, CI

## Idempotent Init Scripts
**Date:** 2026-02-19
**Context:** The mem-skill init.sh must be safe to run multiple times. Users might re-run init after updating the skill, and existing customizations must survive.
**Best Practice:**
- Check `[ ! -f ... ]` before creating any file
- Never overwrite existing `_index.json` files — user may have added custom categories
- Use `mkdir -p` (inherently idempotent) for directory creation
- Print "already exists, skipping" messages for transparency
- Test idempotency explicitly: init once, add custom content, init again, verify content preserved
**Keywords:** init, idempotent, shell, safety, overwrite, preserve

## Version Bump Automation
**Date:** 2026-02-19
**Context:** Multiple files in a skill may contain version numbers (package.json, _index.json, .mem-skill.config.json). Manual version updates are error-prone, especially after bug fixes.
**Best Practice:**
- Create a `scripts/bump-version.sh` that atomically updates ALL version-bearing files
- Support patch/minor/major semver bumps
- Output the old→new version and git commands for next steps
- Use Python's json module for reliable JSON manipulation (not sed/awk on JSON)
- Run bump-version before tagging releases
**Keywords:** version, semver, bump, release, package, automation
