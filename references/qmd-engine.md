# QMD Memory Engine Reference

This reference covers how mem-skill integrates with [QMD](https://github.com/tobi/qmd) (Query Markup Documents) as a memory engine for semantic search over the knowledge base and experience store.

## What is QMD

QMD is an on-device search engine that combines:
- **BM25 full-text search** (SQLite FTS5)
- **Vector semantic search** (local GGUF embeddings via node-llama-cpp)
- **LLM re-ranking** (hybrid query expansion + reciprocal rank fusion)

All processing runs locally. No data leaves the machine.

## Requirements

- Node.js >= 22
- `npm install -g @tobilu/qmd` (or `bun install -g @tobilu/qmd`)
- macOS: `brew install sqlite` (for extension support)
- ~2GB disk for auto-downloaded GGUF models (cached in `~/.cache/qmd/models/`)

## Setup (Performed by `/mem-skill init --mem-engine=qmd`)

During init, the user is prompted for:
1. **Scope** — `project` (collections scoped to this workspace) or `global` (shared across workspaces)
2. **Collection names** — defaults are `<project-folder>-knowledge` / `<project-folder>-experience` for project scope, or `mem-knowledge` / `mem-experience` for global scope

```bash
# Install QMD globally
npm install -g @tobilu/qmd

# Create collections with user-chosen names
qmd collection add <workspace>/knowledge-base --name <knowledge-collection> --mask "**/*.md"
qmd collection add <workspace>/experience --name <experience-collection> --mask "**/*.md"

# Add context descriptions (improves search relevance)
qmd context add qmd://<knowledge-collection> "General knowledge base: reusable workflows, user preferences, best practices, decision logic"
qmd context add qmd://<experience-collection> "Skill-specific experience: pitfalls, parameters, error fixes, successful configurations"

# Generate initial embeddings
qmd embed
```

Collection names are stored in `.mem-skill.config.json` and read by all subsequent commands.

## Retrieval Commands

All collection names below (`<knowledge>`, `<experience>`) are read from `.mem-skill.config.json` at runtime.

### Keyword Search (Fast)
```bash
qmd search "<keywords>" -c <knowledge> --json -n 10
qmd search "<skill-id>" -c <experience> --json -n 5
```

### Semantic Search (Better Quality)
```bash
qmd vsearch "<natural language query>" -c <knowledge> --json -n 10
```

### Hybrid Search with Re-ranking (Best Quality)
```bash
qmd query "<question or context>" -c <knowledge> --json -n 10 --min-score 0.3
qmd query "<skill-id> <problem description>" -c <experience> --json -n 5 --min-score 0.3
```

### Retrieve Specific Documents
```bash
qmd get "knowledge-base/<category>.md" --full
qmd get "experience/skill-<id>.md" --full
qmd multi-get "knowledge-base/*.md" --json --max-bytes 10240
```

## Post-Write Sync

After writing any knowledge or experience entry, re-index and re-embed:
```bash
qmd update
qmd embed
```

For incremental updates (only changed files are re-processed).

## MCP Server (Optional)

For tighter agent integration, run QMD as an MCP server:

```bash
qmd mcp                    # stdio mode (launched per-client)
qmd mcp --http             # HTTP mode on localhost:8181
qmd mcp --http --daemon    # background daemon
```

MCP tools available:
- `qmd_search` — BM25 keyword search
- `qmd_vector_search` — semantic vector search
- `qmd_deep_search` — hybrid with query expansion and re-ranking
- `qmd_get` — retrieve document by path or docid
- `qmd_multi_get` — retrieve multiple documents (glob, list, docids)
- `qmd_status` — index health and collection info

## Score Interpretation

| Score Range | Meaning            |
|-------------|-------------------|
| 0.8 – 1.0  | Highly relevant    |
| 0.5 – 0.8  | Moderately relevant|
| 0.2 – 0.5  | Somewhat relevant  |
| 0.0 – 0.2  | Low relevance      |

Use `--min-score 0.3` to filter out low-relevance noise when retrieving knowledge.

## When to Use QMD vs Default Engine

| Scenario                          | Recommended Engine |
|-----------------------------------|--------------------|
| Small knowledge base (< 50 entries) | Default (JSON index) |
| Large knowledge base (50+ entries)  | QMD                 |
| Need semantic/fuzzy search          | QMD                 |
| Minimal dependencies preferred      | Default              |
| Agentic workflows with MCP          | QMD                 |
