# Test Plan: 05-experience-write

## Objective
Verify that a skill experience entry can be written and the experience index is correctly updated.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 5.1 | Init workspace | Clean workspace ready |
| 5.2 | Write experience entry for a skill | File created at experience/skill-<id>.md |
| 5.3 | Update experience/_index.json | Skill entry added with correct fields |
| 5.4 | _index.json remains valid JSON | Parseable after modification |
| 5.5 | Entry format matches spec | Has Date, Skill, Context, Solution, Key Files, Keywords |
| 5.6 | Multiple entries in same skill file | Append works without corruption |
