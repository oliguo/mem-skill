# Examples & Integration Tests

This folder contains **real-world simulation tests** for mem-skill. Each subfolder is a self-contained user scenario with its own test plan, test script, and auto-generated report.

> **These files are for development and QA only.** They are excluded from the distributed skill package via `package.json` `files` and `.gitignore`.

## Running All Examples

```bash
bash examples/run_all_examples.sh
```

This will execute every example scenario, generate per-scenario test reports, and produce a summary.

## Scenarios

| # | Folder | Scenario |
|---|--------|----------|
| 1 | `01-init-default/` | Fresh init with default engine — files, JSON, config |
| 2 | `02-init-qmd/` | Init with `--mem-engine=qmd` (checks prompt when QMD missing) |
| 3 | `03-init-idempotent/` | Running init twice preserves existing data |
| 4 | `04-knowledge-write/` | Writing a knowledge base entry and updating the index |
| 5 | `05-experience-write/` | Writing an experience entry and updating the index |
| 6 | `06-keyword-matching/` | Keyword extraction and category matching logic |
| 7 | `07-topic-switch/` | Topic switch detection across turns |
| 8 | `08-dynamic-category/` | Creating a new category when no match exists |
| 9 | `09-version-bump/` | Version is bumped correctly on changes |
| 10 | `10-security-scan/` | No secrets, no dangerous patterns, no sensitive files |

## Per-Scenario Structure

```
examples/01-init-default/
├── TEST_PLAN.md       # Human-readable test plan
├── test.sh            # Automated test script (self-contained)
└── test-report.md     # Auto-generated after test run (gitignored)
```

## Adding a New Scenario

1. Create `examples/NN-name/TEST_PLAN.md` with objectives, steps, and expected results.
2. Create `examples/NN-name/test.sh` that exits 0 on success, 1 on failure.
3. The runner will auto-discover and execute it.
