## Skill Validator: No Angle Brackets in YAML Frontmatter
**Date:** 2026-02-19
**Source:** conversation
**Context:** The official skill-creator `quick_validate.py` rejects `<` and `>` characters in the YAML frontmatter `description` field. When writing a SKILL.md with install instructions like `npx skills add <user>/mem-skill`, the angle brackets around `<user>` cause validation failure.
**Best Practice:**
- Never include angle brackets in YAML frontmatter fields (name, description)
- Move install instructions to README.md instead of the SKILL.md description
- Keep the description under 1024 characters
- Run `quick_validate.py` after every SKILL.md edit
**Related:** [[workflow#Skill Package: Include-List Strategy]], [[skill-mem-skill#Fixing skill-creator validation errors]]
**Keywords:** skill-creator, YAML, frontmatter, validation, angle-brackets, description

## Skill Package: Include-List Strategy
**Date:** 2026-02-19
**Source:** conversation
**Context:** The skill-creator `package_skill.py` uses the `files` array in `package.json` to determine what gets packaged into the `.skill` zip. Examples, tests, and dev files should NOT ship to users.
**Best Practice:**
- Use an include-list in `package.json.files` (whitelist approach)
- Only include: SKILL.md, knowledge-base/, experience/, references/, scripts/
- Never include: examples/, tests/, .venv/, node_modules/, .gitignore
- Test with `package_skill.py` after changing the files list
**Related:** [[workflow#Skill Validator: No Angle Brackets in YAML Frontmatter]]
**Keywords:** skill-creator, package, files, whitelist, zip, distribution

## macOS Compatibility: head and sed Differences
**Date:** 2026-02-19
**Source:** conversation
**Context:** GNU coreutils and macOS BSD utilities have different flags. `head -n -1` (skip last line) is GNU-only and fails silently or errors on macOS. Similarly, `sed -i` requires an empty string argument on macOS (`sed -i ''`).
**Best Practice:**
- Avoid `head -n -1`; use `awk` or `sed` alternatives for cross-platform scripts
- For in-place sed: use `if [[ "$OSTYPE" == "darwin"* ]]; then sed -i ''` pattern
- Always test shell scripts on both macOS and Linux
- Use `python3 -c` for complex text processing to avoid platform issues
**Related:** [[workflow#sed-based Markdown Field Backfilling]], [[skill-mem-skill#Fixing skill-creator validation errors]]
**Keywords:** macOS, BSD, GNU, sed, head, cross-platform, shell, compatibility

## QMD Init: Always Ask for Scope and Collection Names
**Date:** 2026-02-23
**Source:** conversation
**Context:** QMD `collection add` registers collections in a global config. Running `/mem-skill init --mem-engine=qmd` in two different projects with the same default names (`mem-knowledge`, `mem-experience`) silently overwrites the first project's collections.
**Best Practice:**
- Never auto-create QMD collections without asking the user for scope (project vs global) and names
- For project scope, prefix collection names with the sanitized workspace folder name (e.g., `myapp-knowledge`)
- For global scope, use `mem-` prefix (e.g., `mem-knowledge`)
- Store scope, mask, and collection names in `.mem-skill.config.json` so all subsequent commands read them
- SKILL.md instructions must explicitly say "MUST ask" — soft language like "prompt the user" gets ignored by agents
**Related:** [[workflow#CLI Flags to Skip Interactive Prompts]]
**Keywords:** QMD, collection, scope, project, global, naming, collision, init

## CLI Flags to Skip Interactive Prompts
**Date:** 2026-02-23
**Source:** conversation
**Context:** Agents sometimes skip interactive questions even when SKILL.md says to ask. Power users also want one-liner init commands. Solution: add `--qmd-*` flags that, when provided, skip the corresponding prompt.
**Best Practice:**
- Design CLI flags that mirror every interactive question (scope, names, mask)
- If a flag is provided, use it silently; if not, ask interactively
- Keep sensible defaults so bare `/mem-skill init --mem-engine=qmd` still works (just asks everything)
- Document flags in a table in SKILL.md so agents can parse them from the user's command
- Example: `--qmd-scope=project --qmd-knowledge=demo-kb --qmd-experience=demo-exp`
**Related:** [[workflow#QMD Init: Always Ask for Scope and Collection Names]]
**Keywords:** CLI, flags, parameters, interactive, prompts, skip, QMD, automation

## External Best-Practice Review Pattern (Karpathy LLM Wiki)
**Date:** 2026-04-08
**Source:** url:https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
**Context:** Reviewed Karpathy's LLM Wiki gist against mem-skill to identify enhancement opportunities. The wiki demonstrated source provenance, cross-referencing, activity logging, compounding updates, and health-check patterns.
**Related:** [[workflow#CLI Flags to Skip Interactive Prompts]], [[workflow#Upgrade Path for Skill Versions]], [[skill-mem-skill#Implementing 7 LLM Wiki enhancements end-to-end]]
**Best Practice:**
- Compare your skill/tool against established best-practice docs to find structural gaps
- Identify patterns, not just features — Karpathy's wiki showed 7 patterns: provenance, cross-refs, audit logs, compounding, query-filing, lint, ingest
- Implement all improvements in a single coordinated release to avoid partial states
- Update README, SKILL.md, init.sh, and tests together for each enhancement
- Bump version after all enhancements land, not after each one
**Keywords:** best-practice, review, gap-analysis, Karpathy, LLM-wiki, enhancement, patterns

## Upgrade Path for Skill Versions
**Date:** 2026-04-08
**Source:** conversation
**Context:** Existing v1.1.0 users needed a migration path to get v1.2.0 features (new entry fields, log.md). Designed an `--upgrade` flag in init.sh that backfills new fields into existing entries without losing data.
**Related:** [[workflow#sed-based Markdown Field Backfilling]], [[workflow#External Best-Practice Review Pattern (Karpathy LLM Wiki)]], [[skill-mem-skill#Building the upgrade command with idempotent backfill]], [[design-layout#Version Bump Automation]]
**Best Practice:**
- Add an `--upgrade` flag that exits early before normal init flow (prevents accidental re-init)
- Backfill new fields into existing markdown entries using sed with careful anchor-line matching
- Always verify idempotency: running upgrade twice should produce 0 changes on the second run
- Update `.mem-skill.config.json` version as the last step so interrupted upgrades can be re-run
- Document the upgrade path in README.md with a "What's New" feature table
**Keywords:** upgrade, migration, backfill, version, idempotent, init, config

## sed-based Markdown Field Backfilling (macOS-compatible)
**Date:** 2026-04-08
**Source:** conversation
**Related:** [[workflow#macOS Compatibility: head and sed Differences]], [[workflow#Upgrade Path for Skill Versions]]
**Context:** Needed to inject new fields (Source, Related) into existing markdown entries at precise locations — after `**Date:**` and before `**Keywords:**` — without disturbing other content.
**Best Practice:**
- Use anchor-line matching with sed: `/^\*\*Date:\*\*/a\` to insert after Date, `/^\*\*Keywords:\*\*/i\` to insert before Keywords
- macOS requires `sed -i '' 'command'` while Linux uses `sed -i 'command'` — detect with `$OSTYPE == darwin*`
- Count affected files before and after to report progress (e.g., "Backfilled Source on 2 file(s)")
- Skip files that already have the field using grep guard: `grep -L '^\*\*Source:\*\*'` to find only missing ones
- Test on a disposable fixture workspace before running on real data
**Keywords:** sed, backfill, markdown, macOS, BSD, field-injection, upgrade
