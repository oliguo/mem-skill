# Test Plan: 02-init-qmd

## Objective
Verify that `/mem-skill init --mem-engine=qmd` handles QMD presence/absence correctly.

## Preconditions
- Empty directory
- QMD may or may not be installed globally

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 2.1 | Run init --mem-engine=qmd when QMD is NOT installed | Script detects missing QMD, prompts user, exits 1 on decline |
| 2.2 | Config would set engine=qmd | The script references "qmd" engine in config block |
| 2.3 | Script checks for QMD binary | `command -v qmd` or `which qmd` present in script |
| 2.4 | Script sets up collections | Contains `qmd collection add` commands |
| 2.5 | Script runs qmd embed | Contains `qmd embed` command |
