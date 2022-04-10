#!/bin/sh
#
# Convert the miners server listing
# into an ufdbGuard domains.
# Modified by Y.Voinov (c) 2014,2018

# Variables
list_="https://raw.githubusercontent.com/Marfjeh/coinhive-block/master/domains"
dst_dir="/usr/local/ufdbguard/blacklists/miners"
work_dir="/tmp"
filteruser="ufdb"
filtergroup="ufdb"

# OS commands
AWK=`which awk`
CHOWN=`which chown`
ECHO=`which echo`
GREP=`which grep`
MV=`which mv`
PRINTF=`which printf`
TOUCH=`which touch`
WGET=`which wget`

$ECHO "List downloading..."
$WGET -O $work_dir/miners $list_ && \
$ECHO "Move to blacklists directory..."
$MV $work_dir/miners $dst_dir/domains

# Change permission
$PRINTF "Set permissions..."
$CHOWN $filteruser:$filtergroup $dst_dir/domains
$ECHO "Done."

# Update date'n-time
$PRINTF "Update date and time to current..."
$TOUCH $dst_dir/*
$ECHO "Done."
#