#!/bin/bash
# Install glean-factory-skills into ~/.claude/skills/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

for skill in glean-build glean-validate glean-repair-workflow glean-extract glean-discover; do
  src="$SCRIPT_DIR/skills/${skill}.md"
  dest="$SKILLS_DIR/${skill}.md"
  if [ -f "$src" ]; then
    ln -sf "$src" "$dest"
    echo "Linked: $dest -> $src"
  else
    echo "Warning: $src not found, skipping"
  fi
done

echo "Done. Skills installed to $SKILLS_DIR"
