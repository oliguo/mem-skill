# Test Plan: 09-version-bump

## Objective
Verify that version bumping in package.json works correctly and tracks changes.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 9.1 | Read current version | Parses x.y.z from package.json |
| 9.2 | Patch bump (z+1) | 1.0.0 → 1.0.1 |
| 9.3 | Minor bump (y+1) | 1.0.1 → 1.1.0 |
| 9.4 | Major bump (x+1) | 1.1.0 → 2.0.0 |
| 9.5 | package.json remains valid JSON | Parseable after bump |
| 9.6 | Version tag format valid | Matches semver regex |
