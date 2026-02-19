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

---

## Real-World Example

Here's an actual conversation showing mem-skill in action. The user asks their AI to build a landing page — mem-skill runs silently in the background the entire time.

### 1. Initialize

```
You:   /mem-skill init
Agent: ✓ Created knowledge-base/_index.json
       ✓ Created experience/_index.json
       ✓ Created .mem-skill.config.json
       mem-skill initialized.
```

### 2. Work Normally

You just ask for what you need. mem-skill reads the knowledge base automatically:

```
You:   Help me write a simple landing page about NVDA stock introduction
Agent: [reads knowledge-base/_index.json — looking for matching categories]
       ...builds the page...
       Created nvda-landing.html
```

The agent creates a professional landing page with hero section, features grid, company stats, CTAs, and responsive design — all in one HTML file.

### 3. mem-skill Learns (With Your Permission)

When you're happy with the result, mem-skill asks before recording:

```
You:   It is OK
Agent: Great! I'd like to record this approach in my knowledge base
       so I can reference it for future landing page requests.
       Is that okay?
You:   Yes
Agent: ✓ Created knowledge-base/landing-pages.md
       ✓ Updated knowledge-base/_index.json
       Recorded!
```

### 4. Next Time It Remembers

The next time you (or anyone using this workspace) ask for a landing page, mem-skill will automatically surface the recorded approach — the single-file HTML pattern, the hero-features-stats-CTA structure, the responsive grid, and the disclaimer for financial topics. No re-explaining needed.

---

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

Uses [QMD](https://github.com/tobi/qmd) for hybrid semantic search (BM25 + vector + LLM re-ranking). Requires Node.js >= 22. The init process will:

1. Install QMD if not already available
2. Ask whether collections should be **project-scoped** or **global**
3. Ask you to **name your collections** (with sensible defaults)

This prevents one project's collections from overwriting another's.

## Memory Engines

| Engine    | Search Method              | Dependencies     | Best For                     |
|-----------|---------------------------|-------------------|------------------------------|
| `default` | JSON keyword matching      | None              | Small knowledge bases (< 50) |
| `qmd`     | BM25 + Vector + Re-ranking | Node.js >= 22, QMD | Large bases, semantic search  |

More engines can be added — see [references/engines.md](references/engines.md) for the extension architecture.

## How It Works

### The Core Loop (Runs Every Turn)

```
┌─────────────────────────────────────────────────────────────────┐
│                    mem-skill Core Loop                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Step 1: Extract Keywords                                        │
│     "help me write a landing page about NVDA stock"              │
│     → keywords: [landing-page, NVDA, stock, HTML, introduction]  │
│                                                                  │
│  Step 2: Detect Topic Switch                                     │
│     Compare with last turn's keywords (>= 40% changed? → yes)   │
│     → Topic switch detected → will re-read knowledge base        │
│                                                                  │
│  Step 3: Load Skill Experience                                   │
│     If another skill is active, load its recorded pitfalls       │
│     → (no other skill this turn — skip)                          │
│                                                                  │
│  Step 4: Load Knowledge Base                                     │
│     Match keywords against category index                        │
│     → Match found: "frontend-dev" (HTML, CSS, component)         │
│     → Load knowledge-base/frontend-dev.md                        │
│                                                                  │
│  Step 5: Proactive Recording                                     │
│     User says "it is OK" → task completed successfully           │
│     → Ask permission → record to knowledge-base/landing-pages.md │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### What Gets Recorded

mem-skill stores two types of memory:

**Knowledge Base** — reusable patterns, best practices, and preferences:

```markdown
## Single-File Landing Page Pattern
**Date:** 2026-02-19
**Context:** Building quick stock/product intro landing pages
**Best Practice:**
- Use single HTML file with embedded CSS for portability
- Structure: Hero → Features grid → Stats → CTA → Footer
- Use responsive CSS Grid (auto-fit, minmax) for feature cards
- Always include disclaimers for financial/medical content
**Keywords:** landing-page, HTML, responsive, single-file, stock
```

**Skill Experience** — pitfalls and solutions for specific skills:

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

## File Structure

```
<your-workspace>/
├── knowledge-base/
│   ├── _index.json             # Category index (keywords → files)
│   ├── frontend-dev.md         # Recorded: frontend best practices
│   ├── landing-pages.md        # Recorded: landing page patterns
│   └── ...                     # Categories created as you work
├── experience/
│   ├── _index.json             # Skill experience index
│   ├── skill-<id>.md           # Recorded: pitfalls for a specific skill
│   └── ...
├── references/
│   ├── qmd-engine.md           # QMD engine setup & commands
│   └── engines.md              # How to add new engines
├── scripts/
│   ├── init.sh                 # Workspace initialization
│   ├── bump-version.sh         # Version management
│   └── package.sh              # Clean packaging for distribution
├── SKILL.md                    # Core skill definition
├── .mem-skill.config.json      # Engine configuration (generated)
└── package.json
```

## Starter Categories

When you install mem-skill, you start with 5 empty categories ready to be filled:

| Category | Keywords | What Goes Here |
|----------|----------|----------------|
| Frontend Development | React, Vue, CSS, TypeScript, ... | UI patterns, component practices |
| Backend Development | API, Node.js, database, REST, ... | Server patterns, auth flows |
| Writing & Content | article, documentation, blog, ... | Writing styles, templates |
| Design & Layout | UI, UX, color, typography, ... | Design systems, layout rules |
| Workflow & Automation | CI/CD, DevOps, script, ... | Build processes, automation |

New categories are created automatically when your work doesn't fit an existing one — mem-skill will suggest a name and keywords, then create the file for you.

## FAQ

**Does mem-skill send my data anywhere?**
No. Everything stays in your local workspace files. There are no API calls, no telemetry, no cloud storage.

**What if I want to start fresh?**
Delete the `knowledge-base/` and `experience/` directories, then run `/mem-skill init` again.

**Can I edit the recorded entries manually?**
Yes — they're plain Markdown files. Edit, reorganize, or delete entries anytime.

**When should I upgrade to QMD?**
When your knowledge base exceeds ~50 entries. mem-skill will proactively suggest the upgrade when it detects this threshold.

**Does it work with any AI agent?**
It works with any agent that supports the skill-creator framework (Claude Code, Cursor, Codex, etc.).

## Credits

Inspired by [Auto-Skill](https://github.com/Toolsai/auto-skill) (Toolsai) and powered by [QMD](https://github.com/tobi/qmd) (Tobi Lütke).

## License

MIT — see [LICENSE](LICENSE).