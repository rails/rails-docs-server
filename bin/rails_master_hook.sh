#!/bin/bash

set -ex

# this is run by cron, so there are no practical race
# conditions with these checks
if [ ! -e $LOCK_FILE ]; then
    if [ -e $RUN_FILE ] || [ -n "$FORCE" ]; then
        touch $LOCK_FILE
        rm -f $RUN_FILE

        cd ~/rails-docs-server
        nice --adjustment=19 git pull -q
        nice --adjustment=19 bin/generate_docs.rb >> ~/docs_generation.log 2>&1

        # We update the contrib app after docs.
        #
        # This is important, docs generation is expensive,
        # better wipe the cache when that is finished.
        nice --adjustment=19 bin/update_rails_contributors.sh

        rm $LOCK_FILE
    fi
fi
