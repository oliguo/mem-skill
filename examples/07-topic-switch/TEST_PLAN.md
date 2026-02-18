# Test Plan: 07-topic-switch

## Objective
Verify that topic switch detection works when >= 40% of keywords change between turns.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 7.1 | Same keywords → no switch | Overlap >= 60%, no switch |
| 7.2 | 100% different keywords → switch | Overlap 0%, switch detected |
| 7.3 | Exactly 40% change → switch | Overlap 60%, borderline switch |
| 7.4 | 30% change → no switch | Overlap 70%, no switch |
| 7.5 | Empty previous keywords → switch | Fresh context, always switch |
