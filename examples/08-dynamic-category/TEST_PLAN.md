# Test Plan: 08-dynamic-category

## Objective
Verify dynamic category creation when user keywords don't match any existing category.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 8.1 | Init workspace with starter categories | 5 default categories exist |
| 8.2 | Unmatched keywords trigger new category | New category added to _index.json |
| 8.3 | New category has correct schema | id, name, keywords, file, count fields |
| 8.4 | New .md file created for category | File exists at knowledge-base/<id>.md |
| 8.5 | Total category count incremented | 6 categories after addition |
| 8.6 | Subsequent match works on new category | Re-matching finds the new category |
