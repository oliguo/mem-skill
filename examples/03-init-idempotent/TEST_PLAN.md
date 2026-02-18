# Test Plan: 03-init-idempotent

## Objective
Verify that running init twice does not corrupt or overwrite existing data.

## Preconditions
- First init has already run and created files
- User has added custom content to knowledge-base

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 3.1 | First init succeeds | Exit 0, all files created |
| 3.2 | Add custom content to knowledge-base | File written successfully |
| 3.3 | Second init succeeds | Exit 0, no error |
| 3.4 | Custom content preserved | knowledge-base file unchanged |
| 3.5 | _index.json not overwritten | Original lastUpdated retained |
| 3.6 | .mem-skill.config.json rewritten | Config refreshed (acceptable) |
