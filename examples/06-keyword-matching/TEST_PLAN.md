# Test Plan: 06-keyword-matching

## Objective
Verify keyword extraction and category matching logic against real scenarios.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 6.1 | Frontend keywords match frontend-dev category | Correct match |
| 6.2 | Backend keywords match backend-dev category | Correct match |
| 6.3 | Multi-category keywords match multiple | Both matched |
| 6.4 | Unrelated keywords match nothing | Empty match list |
| 6.5 | Case-insensitive matching | "react" matches "React" |
| 6.6 | Partial keywords don't false-match | "Java" doesn't match "JavaScript" index entry |
