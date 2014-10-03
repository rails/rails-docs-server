#!/bin/bash

# Every time edge docs are generated a new *.mobi file gets created. These take
# space and can eventually fill the disk.
#
# This script is run by a cron job to keep them under control.

cd ~/master/guides/output/kindle
ls -t *.mobi | tail -n+2 | xargs rm -f
