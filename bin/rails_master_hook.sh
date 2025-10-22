#!/bin/bash

set -e

cleanup() {
    echo "🧹 Cleaning up lock file: $LOCK_FILE"
    rm -f "$LOCK_FILE"
}

# this is run by cron, so there are no practical race
# conditions with these checks
if [ ! -e $LOCK_FILE ]; then
    if [ -e $RUN_FILE ] || [ -n "$FORCE" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "▶ Starting rails-master-hook execution"
        touch $LOCK_FILE
        # Ensure lock file is removed even if the script fails
        trap cleanup EXIT

        rm -f $RUN_FILE

        cd ~/rails-docs-server
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
        nice --adjustment=19 bin/generate_docs.rb >> ~/docs_generation.log 2>&1

        # We update the contrib app after docs.
        #
        # This is important, docs generation is expensive,
        # better wipe the cache when that is finished.
        echo "▶ Updating Rails contributors..."
        nice --adjustment=19 bin/update_rails_contributors.sh

        echo "✓ Execution completed successfully"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
else
    echo "⏸ Skipping execution: lock file exists at $LOCK_FILE"
fi
