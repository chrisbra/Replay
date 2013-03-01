#!/bin/sh
echo "Starting recording: `date -R`" >&2
echo "Parameters: $@" >&2
echo "==============================" >&2
$@ &
# return pid of screen capturing process so we can kill it later
echo $!
