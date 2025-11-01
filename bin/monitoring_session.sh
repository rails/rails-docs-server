#!/usr/bin/env bash

set -euo pipefail

SESSION_NAME="${1:-rails-docs-monitor}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is not installed or not found in PATH." >&2
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  exec tmux attach -t "$SESSION_NAME"
fi

# Bootstrap the monitoring windows when the session does not already exist.
tmux new-session -d -s "$SESSION_NAME" -n "btop" -c "$ROOT_DIR" "btop"
# Expand status area so longer session names stay visible.
tmux set-option -t "$SESSION_NAME" status-left-length 40
tmux new-window -t "${SESSION_NAME}":1 -n "docs-log" -c "$HOME" "sudo journalctl -t rails-docs-generator -f"
tmux new-window -t "${SESSION_NAME}":2 -n "puma-hook" -c "$ROOT_DIR" "sudo journalctl -u rails-master-hook_puma_production -f"
tmux new-window -t "${SESSION_NAME}":3 -n "hook-script" -c "$ROOT_DIR" "sudo journalctl -t rails-master-hook -f"
tmux new-window -t "${SESSION_NAME}":4 -n "puma-contributors" -c "$ROOT_DIR" "sudo journalctl -u rails-contributors_puma_production -f"

tmux select-window -t "${SESSION_NAME}":1
exec tmux attach -t "$SESSION_NAME"
