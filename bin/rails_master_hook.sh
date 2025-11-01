#!/bin/bash

set -eo pipefail

: "${LOCK_FILE:?LOCK_FILE must be set}"
: "${RUN_FILE:?RUN_FILE must be set}"

lock_acquired=0

cleanup() {
    trap - EXIT ERR SIGINT SIGTERM
    if (( lock_acquired )); then
        echo "🧹 Cleaning up lock file: $LOCK_FILE"
        rm -f "$LOCK_FILE" || true
    fi
}

trap cleanup EXIT ERR SIGINT SIGTERM

# this is run by cron, so there are no practical race
# conditions with these checks
if [ ! -e "$LOCK_FILE" ]; then
    if [ -e "$RUN_FILE" ] || [ -n "${FORCE:-}" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "▶ Starting rails-master-hook execution"
        touch "$LOCK_FILE"
        lock_acquired=1

        rm -f "$RUN_FILE"

        cd "$HOME/rails-docs-server"
        echo "▶ Pulling latest changes from repository..."
        nice --adjustment=19 git pull -q

        # Ensure ~/.profile sources our config/profile
        if ! grep -q "rails-docs-server/config/profile" ~/.profile 2>/dev/null; then
            echo "▶ Updating ~/.profile to source rails-docs-server configuration..."
            echo "" >> ~/.profile
            echo "# Source rails-docs-server environment configuration" >> ~/.profile
            echo "[ -f ~/rails-docs-server/config/profile ] && . ~/rails-docs-server/config/profile" >> ~/.profile
        fi

        echo "▶ Generating documentation..."
        docs_failed=0
        if ! nice --adjustment=19 bin/generate_docs.rb >> "$HOME/docs_generation.log" 2>&1; then
            docs_failed=1
            echo "⚠️ Documentation generation failed; continuing with contributor update."
        fi

        # We update the contrib app after docs.
        #
        # This is important, docs generation is expensive,
        # better wipe the cache when that is finished.
        echo "▶ Updating Rails contributors..."
        contributors_failed=0
        if ! nice --adjustment=19 bin/update_rails_contributors.sh; then
            contributors_failed=1
            echo "⚠️ Contributor update failed."
        fi

        if (( docs_failed || contributors_failed )); then
            echo "✗ Execution finished with errors"
            cleanup
            exit 1
        fi

        cleanup
        echo "✓ Execution completed successfully"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
else
    echo "⏸ Skipping execution: lock file exists at $LOCK_FILE"
fi
