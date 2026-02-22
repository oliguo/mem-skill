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

## QMD Init: Always Ask for Scope and Collection Names
**Date:** 2026-02-23
**Context:** QMD `collection add` registers collections in a global config. Running `/mem-skill init --mem-engine=qmd` in two different projects with the same default names (`mem-knowledge`, `mem-experience`) silently overwrites the first project's collections.
**Best Practice:**
- Never auto-create QMD collections without asking the user for scope (project vs global) and names
- For project scope, prefix collection names with the sanitized workspace folder name (e.g., `myapp-knowledge`)
- For global scope, use `mem-` prefix (e.g., `mem-knowledge`)
- Store scope, mask, and collection names in `.mem-skill.config.json` so all subsequent commands read them
- SKILL.md instructions must explicitly say "MUST ask" — soft language like "prompt the user" gets ignored by agents
**Keywords:** QMD, collection, scope, project, global, naming, collision, init

## CLI Flags to Skip Interactive Prompts
**Date:** 2026-02-23
**Context:** Agents sometimes skip interactive questions even when SKILL.md says to ask. Power users also want one-liner init commands. Solution: add `--qmd-*` flags that, when provided, skip the corresponding prompt.
**Best Practice:**
- Design CLI flags that mirror every interactive question (scope, names, mask)
- If a flag is provided, use it silently; if not, ask interactively
- Keep sensible defaults so bare `/mem-skill init --mem-engine=qmd` still works (just asks everything)
- Document flags in a table in SKILL.md so agents can parse them from the user's command
- Example: `--qmd-scope=project --qmd-knowledge=demo-kb --qmd-experience=demo-exp`
**Keywords:** CLI, flags, parameters, interactive, prompts, skip, QMD, automation
