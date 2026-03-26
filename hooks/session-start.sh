#!/bin/bash
# crinity-dev plugin — SessionStart hook
# Checks that project-specific files are present

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

check_file() {
  if [ ! -f "$PROJECT_ROOT/$1" ]; then
    echo "[crinity-dev] WARNING: Missing required file: $1"
    echo "  This file contains project-specific rules needed by the agents."
    echo "  Run '/plugin-setup' to auto-generate it from your codebase."
    MISSING=1
  fi
}

MISSING=0

check_file "CLAUDE.md"
check_file ".claude/rules/architecture.md"
check_file ".claude/rules/backend-rules.md"
check_file ".claude/rules/frontend-rules.md"
check_file ".claude/rules/frontend-ui.md"
check_file ".claude/rules/prohibitions.md"
check_file ".claude/rules/build-commands.md"
check_file ".claude/rules/review-checklist.md"

# references (에이전트 참조 문서 — plugin-setup이 복사)
check_file ".claude/references/planner-output-format.md"
check_file ".claude/references/session-context.md"

if [ "$MISSING" -eq 1 ]; then
  echo "[crinity-dev] Some required project files are missing."
  echo "  Agents may not function correctly without these files."
  echo "  Run '/plugin-setup' to auto-generate the missing files from your codebase."
else
  echo "[crinity-dev] Environment check passed. All required project files found."
fi
