#!/usr/bin/env bash
# mem-skill init script
# Usage: bash init.sh [--mem-engine=qmd]
#
# Initializes the mem-skill knowledge base and experience directories
# in the current working directory.

set -euo pipefail

WORKSPACE="$(pwd)"
ENGINE="default"

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --mem-engine=*)
      ENGINE="${arg#*=}"
      ;;
    --help|-h)
      echo "Usage: bash init.sh [--mem-engine=<engine>]"
      echo ""
      echo "Options:"
      echo "  --mem-engine=<engine>  Memory engine to use (default: default)"
      echo "                         Available: default, qmd"
      echo ""
      echo "Examples:"
      echo "  bash init.sh"
      echo "  bash init.sh --mem-engine=qmd"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run 'bash init.sh --help' for usage."
      exit 1
      ;;
  esac
done

echo "==> Initializing mem-skill in: $WORKSPACE"
echo "    Engine: $ENGINE"

# --- Create directories ---
mkdir -p "$WORKSPACE/knowledge-base"
mkdir -p "$WORKSPACE/experience"

# --- Populate knowledge-base/_index.json ---
if [ ! -f "$WORKSPACE/knowledge-base/_index.json" ]; then
  cat > "$WORKSPACE/knowledge-base/_index.json" <<'EOF'
{
  "lastUpdated": "YYYY-MM-DD",
  "version": "1.0.0",
  "totalEntries": 0,
  "categories": [],
  "absorbedSkills": []
}
EOF
  # Update the date
  TODAY=$(date +%Y-%m-%d)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/YYYY-MM-DD/$TODAY/" "$WORKSPACE/knowledge-base/_index.json"
  else
    sed -i "s/YYYY-MM-DD/$TODAY/" "$WORKSPACE/knowledge-base/_index.json"
  fi
  echo "    Created knowledge-base/_index.json"
else
  echo "    knowledge-base/_index.json already exists, skipping."
fi

# --- Populate experience/_index.json ---
if [ ! -f "$WORKSPACE/experience/_index.json" ]; then
  cat > "$WORKSPACE/experience/_index.json" <<'EOF'
{
  "lastUpdated": "YYYY-MM-DD",
  "version": "1.0.0",
  "skills": []
}
EOF
  TODAY=$(date +%Y-%m-%d)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/YYYY-MM-DD/$TODAY/" "$WORKSPACE/experience/_index.json"
  else
    sed -i "s/YYYY-MM-DD/$TODAY/" "$WORKSPACE/experience/_index.json"
  fi
  echo "    Created experience/_index.json"
else
  echo "    experience/_index.json already exists, skipping."
fi

# --- Engine-specific setup ---
if [ "$ENGINE" = "qmd" ]; then
  echo ""
  echo "==> Setting up QMD memory engine..."

  # Check if QMD is installed
  if ! command -v qmd &> /dev/null; then
    echo ""
    echo "    QMD is not installed."
    echo "    Install with:  npm install -g @tobilu/qmd"
    echo "    Requires: Node.js >= 22"
    echo ""
    read -p "    Install QMD now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      npm install -g @tobilu/qmd
    else
      echo "    Skipping QMD installation. You can install it later and re-run init."
      exit 1
    fi
  fi

  echo "    Creating QMD collections..."
  qmd collection add "$WORKSPACE/knowledge-base" --name mem-knowledge --mask "**/*.md"
  qmd collection add "$WORKSPACE/experience" --name mem-experience --mask "**/*.md"

  echo "    Adding QMD context..."
  qmd context add qmd://mem-knowledge "General knowledge base: reusable workflows, preferences, best practices"
  qmd context add qmd://mem-experience "Skill-specific experience: pitfalls, parameters, solutions"

  echo "    Generating embeddings..."
  qmd embed

  # Write config
  cat > "$WORKSPACE/.mem-skill.config.json" <<'EOF'
{
  "engine": "qmd",
  "version": "1.0.0",
  "collections": {
    "knowledge": "mem-knowledge",
    "experience": "mem-experience"
  }
}
EOF
  echo "    Created .mem-skill.config.json (engine: qmd)"

elif [ "$ENGINE" = "default" ]; then
  # Write config
  cat > "$WORKSPACE/.mem-skill.config.json" <<'EOF'
{
  "engine": "default",
  "version": "1.0.0"
}
EOF
  echo "    Created .mem-skill.config.json (engine: default)"

else
  echo "    Unknown engine: $ENGINE"
  echo "    Available engines: default, qmd"
  exit 1
fi

echo ""
echo "==> mem-skill initialized successfully!"
echo "    Knowledge base: $WORKSPACE/knowledge-base/"
echo "    Experience:      $WORKSPACE/experience/"
echo "    Config:          $WORKSPACE/.mem-skill.config.json"
echo "    Engine:          $ENGINE"
