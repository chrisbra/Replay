#!/bin/sh
$@ &
# return pid of screen capturing process so we can kill it later
echo $!
