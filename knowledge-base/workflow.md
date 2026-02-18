## Skill Validator: No Angle Brackets in YAML Frontmatter
**Date:** 2026-02-19
**Context:** The official skill-creator `quick_validate.py` rejects `<` and `>` characters in the YAML frontmatter `description` field. When writing a SKILL.md with install instructions like `npx skills add <user>/mem-skill`, the angle brackets around `<user>` cause validation failure.
**Best Practice:**
- Never include angle brackets in YAML frontmatter fields (name, description)
- Move install instructions to README.md instead of the SKILL.md description
- Keep the description under 1024 characters
- Run `quick_validate.py` after every SKILL.md edit
**Keywords:** skill-creator, YAML, frontmatter, validation, angle-brackets, description

## Skill Package: Include-List Strategy
**Date:** 2026-02-19
**Context:** The skill-creator `package_skill.py` uses the `files` array in `package.json` to determine what gets packaged into the `.skill` zip. Examples, tests, and dev files should NOT ship to users.
**Best Practice:**
- Use an include-list in `package.json.files` (whitelist approach)
- Only include: SKILL.md, knowledge-base/, experience/, references/, scripts/
- Never include: examples/, tests/, .venv/, node_modules/, .gitignore
- Test with `package_skill.py` after changing the files list
**Keywords:** skill-creator, package, files, whitelist, zip, distribution

## macOS Compatibility: head and sed Differences
**Date:** 2026-02-19
**Context:** GNU coreutils and macOS BSD utilities have different flags. `head -n -1` (skip last line) is GNU-only and fails silently or errors on macOS. Similarly, `sed -i` requires an empty string argument on macOS (`sed -i ''`).
**Best Practice:**
- Avoid `head -n -1`; use `awk` or `sed` alternatives for cross-platform scripts
- For in-place sed: use `if [[ "$OSTYPE" == "darwin"* ]]; then sed -i ''` pattern
- Always test shell scripts on both macOS and Linux
- Use `python3 -c` for complex text processing to avoid platform issues
**Keywords:** macOS, BSD, GNU, sed, head, cross-platform, shell, compatibility
