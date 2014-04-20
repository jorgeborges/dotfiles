#!/bin/sh
# Open a file in Quicklook from the command line

qlmanage -p "$@" >& /dev/null &
