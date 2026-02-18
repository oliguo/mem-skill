# Test Plan: 04-knowledge-write

## Objective
Verify that a knowledge base entry can be written and the _index.json is correctly updated.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 4.1 | Init workspace | Clean workspace ready |
| 4.2 | Write a new category md file | File created with correct entry format |
| 4.3 | Update _index.json with new category | Category added, count incremented |
| 4.4 | _index.json remains valid JSON | Parseable after modification |
| 4.5 | totalEntries incremented | Matches actual count |
| 4.6 | lastUpdated refreshed | Updated to today |
| 4.7 | Entry format matches spec | Has Date, Context, Best Practice, Keywords |
