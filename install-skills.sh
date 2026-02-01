#!/bin/bash
#
# install-skills.sh - Install skills to ~/.claude/skills/
#
# This script copies skills from this repository to the user's Claude Code
# skills directory, making them available in all Claude Code sessions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="${SCRIPT_DIR}/skills"
SKILLS_TARGET="${HOME}/.claude/skills"

# Check source directory exists
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo "Error: Skills source directory not found: $SKILLS_SOURCE"
    exit 1
fi

# Create target directory if needed
mkdir -p "$SKILLS_TARGET"

# Install each skill
for skill_dir in "$SKILLS_SOURCE"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name="$(basename "$skill_dir")"
        target_dir="${SKILLS_TARGET}/${skill_name}"

        echo "Installing skill: $skill_name"

        # Remove existing skill if present
        rm -rf "$target_dir"

        # Copy skill files
        cp -r "$skill_dir" "$target_dir"

        # Make scripts executable
        if [ -d "$target_dir/scripts" ]; then
            chmod +x "$target_dir/scripts"/*.sh 2>/dev/null || true
        fi

        echo "  -> $target_dir"
    fi
done

echo ""
echo "Skills installed successfully."
echo ""
echo "Available skills:"
for skill_dir in "$SKILLS_TARGET"/*/; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        echo "  - /$skill_name"
    fi
done
echo ""
echo "To use a skill, start a Claude Code session and invoke it with /skill-name"
echo "or ask Claude to perform the related task."
