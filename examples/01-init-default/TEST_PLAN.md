# Test Plan: 01-init-default

## Objective
Verify that `/mem-skill init` (default engine) creates a correct workspace from scratch.

## Preconditions
- Empty directory (no prior mem-skill data)

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 1.1 | Run init.sh with no flags | Exit 0, directories created |
| 1.2 | knowledge-base/_index.json exists | File exists, valid JSON |
| 1.3 | experience/_index.json exists | File exists, valid JSON |
| 1.4 | .mem-skill.config.json exists | `engine` is `"default"` |
| 1.5 | knowledge-base/_index.json has correct schema | Has lastUpdated, version, totalEntries, categories |
| 1.6 | experience/_index.json has correct schema | Has lastUpdated, version, skills |
| 1.7 | lastUpdated is today's date | YYYY-MM-DD format, equals today |
| 1.8 | No extra files created | Only expected files present |
