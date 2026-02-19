#!/usr/bin/env bash
# mem-skill init script
# Usage: bash init.sh [--mem-engine=qmd] [--qmd-scope=project|global]
#        [--qmd-knowledge=name] [--qmd-experience=name] [--qmd-mask=pattern]
#
# Initializes the mem-skill knowledge base and experience directories
# in the current working directory.

set -euo pipefail

WORKSPACE="$(pwd)"
ENGINE="default"
QMD_SCOPE=""
QMD_KNOWLEDGE=""
QMD_EXPERIENCE=""
QMD_MASK="**/*.md"

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --mem-engine=*)
      ENGINE="${arg#*=}"
      ;;
    --qmd-scope=*)
      QMD_SCOPE="${arg#*=}"
      ;;
    --qmd-knowledge=*)
      QMD_KNOWLEDGE="${arg#*=}"
      ;;
    --qmd-experience=*)
      QMD_EXPERIENCE="${arg#*=}"
      ;;
    --qmd-mask=*)
      QMD_MASK="${arg#*=}"
      ;;
    --help|-h)
      echo "Usage: bash init.sh [--mem-engine=<engine>] [QMD options]"
      echo ""
      echo "Options:"
      echo "  --mem-engine=<engine>       Memory engine (default: default)"
      echo "                              Available: default, qmd"
      echo ""
      echo "QMD options (only used with --mem-engine=qmd):"
      echo "  --qmd-scope=<scope>         Collection scope: project or global"
      echo "  --qmd-knowledge=<name>      Knowledge collection name"
      echo "  --qmd-experience=<name>     Experience collection name"
      echo "  --qmd-mask=<pattern>        File mask for collections (default: **/*.md)"
      echo ""
      echo "Examples:"
      echo "  bash init.sh"
      echo "  bash init.sh --mem-engine=qmd"
      echo "  bash init.sh --mem-engine=qmd --qmd-scope=project"
      echo "  bash init.sh --mem-engine=qmd --qmd-scope=global --qmd-knowledge=my-kb --qmd-experience=my-exp"
      echo "  bash init.sh --mem-engine=qmd --qmd-mask='**/*.md,**/*.txt'"
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

  # --- Determine scope (from flag or interactive) ---
  FOLDER_NAME=$(basename "$WORKSPACE")
  if [ -n "$QMD_SCOPE" ]; then
    SCOPE="$QMD_SCOPE"
  else
    echo ""
    echo "    Where should QMD collections be stored?"
    echo "      1) Project  — scoped to this workspace (recommended for multi-project setups)"
    echo "      2) Global   — shared across all workspaces"
    echo ""
    read -p "    Choose [1/2] (default: 1): " SCOPE_CHOICE
    SCOPE_CHOICE="${SCOPE_CHOICE:-1}"
    if [ "$SCOPE_CHOICE" = "2" ]; then
      SCOPE="global"
    else
      SCOPE="project"
    fi
  fi

  # --- Compute default prefix ---
  if [ "$SCOPE" = "global" ]; then
    DEFAULT_PREFIX="mem"
  else
    # Sanitize folder name: lowercase, replace spaces/special chars with hyphens
    DEFAULT_PREFIX=$(echo "$FOLDER_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
    DEFAULT_PREFIX="${DEFAULT_PREFIX:-mem}"
  fi

  # --- Determine collection names (from flags or interactive) ---
  if [ -n "$QMD_KNOWLEDGE" ]; then
    KNOWLEDGE_NAME="$QMD_KNOWLEDGE"
  else
    echo ""
    read -p "    Knowledge collection name (default: ${DEFAULT_PREFIX}-knowledge): " KNOWLEDGE_NAME
    KNOWLEDGE_NAME="${KNOWLEDGE_NAME:-${DEFAULT_PREFIX}-knowledge}"
  fi

  if [ -n "$QMD_EXPERIENCE" ]; then
    EXPERIENCE_NAME="$QMD_EXPERIENCE"
  else
    read -p "    Experience collection name (default: ${DEFAULT_PREFIX}-experience): " EXPERIENCE_NAME
    EXPERIENCE_NAME="${EXPERIENCE_NAME:-${DEFAULT_PREFIX}-experience}"
  fi

  echo ""
  echo "    Scope:                $SCOPE"
  echo "    Knowledge collection: $KNOWLEDGE_NAME"
  echo "    Experience collection: $EXPERIENCE_NAME"
  echo ""

  echo "    Creating QMD collections..."
  qmd collection add "$WORKSPACE/knowledge-base" --name "$KNOWLEDGE_NAME" --mask "$QMD_MASK"
  qmd collection add "$WORKSPACE/experience" --name "$EXPERIENCE_NAME" --mask "$QMD_MASK"

  echo "    Adding QMD context..."
  qmd context add "qmd://$KNOWLEDGE_NAME" "General knowledge base: reusable workflows, preferences, best practices"
  qmd context add "qmd://$EXPERIENCE_NAME" "Skill-specific experience: pitfalls, parameters, solutions"

  echo "    Generating embeddings..."
  qmd embed

  # Write config with scope and user-chosen names
  cat > "$WORKSPACE/.mem-skill.config.json" <<EOF
{
  "engine": "qmd",
  "version": "1.0.0",
  "scope": "$SCOPE",
  "mask": "$QMD_MASK",
  "collections": {
    "knowledge": "$KNOWLEDGE_NAME",
    "experience": "$EXPERIENCE_NAME"
  }
}
EOF
  echo "    Created .mem-skill.config.json (engine: qmd, scope: $SCOPE)"

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
