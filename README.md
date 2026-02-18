# mem-skill

A self-evolving memory and knowledge accumulation skill for AI agents. Turn your AI assistant from a "use-and-forget" tool into a **persistent second brain** that gets smarter with every conversation.

## What It Does

mem-skill runs as a background meta-skill for AI agents (Claude Code, Cursor, Codex, etc.). On every conversation turn, it:

1. **Extracts keywords** from your request to build a topic fingerprint.
2. **Detects topic switches** to decide when to re-read the knowledge base.
3. **Loads skill experience** when you use another skill — if it has recorded pitfalls or best practices, it surfaces them immediately.
4. **Retrieves relevant knowledge** from your personal knowledge base.
5. **Proactively records** successful solutions when a task is completed, asking your permission before writing.

Over time, your AI remembers what worked, what failed, and how you prefer things done.

## Installation

### As an Agent Skill

```bash
npx skills add oliguo/mem-skill
```

### From Source

```bash
git clone https://github.com/oliguo/mem-skill.git
cp -r mem-skill ~/.agents/skills/mem-skill
```

## Quick Start

### Initialize (Default Engine)

```bash
/mem-skill init
```

Creates `knowledge-base/` and `experience/` directories with starter index files, using simple JSON keyword matching.

### Initialize with QMD Engine

```bash
/mem-skill init --mem-engine=qmd
```

Uses [QMD](https://github.com/tobi/qmd) for hybrid semantic search (BM25 + vector + LLM re-ranking). Requires Node.js >= 22. The init process will prompt you to install QMD if it's not already available.

## Memory Engines

| Engine    | Search Method              | Dependencies     | Best For                     |
|-----------|---------------------------|-------------------|------------------------------|
| `default` | JSON keyword matching      | None              | Small knowledge bases (< 50) |
| `qmd`     | BM25 + Vector + Re-ranking | Node.js >= 22, QMD | Large bases, semantic search  |

More engines can be added — see [references/engines.md](references/engines.md) for the extension architecture.

## File Structure

```
<your-workspace>/
├── SKILL.md                    # Skill definition (core loop, formats, rules)
├── knowledge-base/
│   ├── _index.json             # Keyword index for categories
│   ├── frontend-dev.md         # Category: Frontend Development
│   ├── backend-dev.md          # Category: Backend Development
│   └── ...                     # More categories created dynamically
├── experience/
│   ├── _index.json             # Skill experience index
│   ├── skill-<id>.md           # Experience for a specific skill
│   └── ...
├── references/
│   ├── qmd-engine.md           # QMD engine reference
│   └── engines.md              # Engine abstraction guide
├── scripts/
│   └── init.sh                 # Init script
├── .mem-skill.config.json      # Engine configuration
└── package.json                # For npx distribution
```

## How the Core Loop Works

```
┌─────────────────────────────────────────────────────────┐
│                  mem-skill Core Loop                      │
│                  (runs every turn)                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Step 1: Extract Keywords                                │
│     └── 3–8 core terms from user message                 │
│                                                          │
│  Step 2: Detect Topic Switch                             │
│     └── Compare keywords vs last turn (>= 40% change?)  │
│                                                          │
│  Step 3: Load Skill Experience (forced)                  │
│     └── If another skill is active, check experience/    │
│                                                          │
│  Step 4: Load Knowledge Base (on topic switch only)      │
│     └── Match keywords → load category files             │
│                                                          │
│  Step 5: Proactive Recording (on task completion)        │
│     └── Summarize → evaluate value → ask → write         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Entry Formats

### Knowledge Base Entry
```markdown
## Fix CORS in Development
**Date:** 2026-02-19
**Context:** Local dev server returning 403 on API calls
**Best Practice:**
- Add `Access-Control-Allow-Origin: *` header in dev proxy config
- Never use wildcard CORS in production
**Keywords:** CORS, proxy, development, API
```

### Experience Entry
```markdown
## QMD embed fails on large directories
**Date:** 2026-02-19
**Skill:** qmd-search
**Context:** Running qmd embed on 500+ files caused OOM
**Solution:**
- Split into smaller collections (< 200 files each)
- Use `--mask` to exclude non-markdown files
**Key Files/Paths:**
- ~/.cache/qmd/models/
**Keywords:** qmd, embed, OOM, large, collection
```

## Credits

Inspired by [Auto-Skill](https://github.com/Toolsai/auto-skill) (Toolsai) and powered by [QMD](https://github.com/tobi/qmd) (Tobi Lütke).

## License

MIT — see [LICENSE](LICENSE).