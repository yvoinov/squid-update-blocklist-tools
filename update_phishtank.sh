#!/sbin/sh

# By accepting this notice, you agree to be bound by the following
# agreements:
#
# This script written by Yuri Voinov (C) 2010,2016
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License (version 2) as
# published by the Free Software Foundation.  It is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License (GPL) for more details.
#
# You should have received a copy of the GNU General Public License
# (GPL) along with this program.

#
# ufdbGuard phishtank update
#
# Based on shalla_update.sh, v 0.3.1 20080403
# and update_blocklist.sh, v 1.1-1.9 by Y.Voinov.
#
# ident   "@(#)update_phishtank.sh     1.0     28/06/16 YV"
#

#############
# Variables #
#############

# Key
KEY="Insert_your_fishtank_API_key_here"

# Modify PATH for SFW directory use
PATH=/usr/sfw/bin:$PATH

# List name
LIST_NAME="online-valid.csv.gz"

# Servers for downloading blacklist
SERVER1="http://data.phishtank.com/data/$KEY/$LIST_NAME"
SERVER2=""

SERVER_LIST="$SERVER1 $SERVER2"
TEMP_DIR="/tmp"
WORK_DIR="$TEMP_DIR/phishtank"

# Connection timeout for downloading
TIMEOUT=30

# Redirector user name
RDR_USER="ufdb"
RDR_GROUP="ufdb"

# Installation base dir
BASE="/usr/local"
# Redirector dir base
BASE2=$BASE"/ufdbguard"
# Redirector blacklist base
BASE3=$BASE2"/blacklists"

DIR_CUSTOM2=$BASE3"/phishtank"

# OS utilities
AWK=`which awk`
CAT=`which cat`
CHMOD=`which chmod`
CHOWN=`which chown`
CUT=`which cut`
ECHO=`which echo`
FIND=`which find`
GREP=`which grep`
GZCAT=`which gzcat`
ID=`which id`
MKDIR=`which mkdir`
PRINTF=`which printf`
RM=`which rm`
SED=`which sed`
SORT=`which sort`
TAIL=`which tail`
TOUCH=`which touch`
UNIQ=`which uniq`
WGET=`which wget`

###############
# Subroutines #
###############

root_check ()
{
 if [ ! `$ID | $CUT -f1 -d" "` = "uid=0(root)" ]; then
  $ECHO "ERROR: You must be super-user to run this script."
  exit 1
 fi
}

checkuser ()
{
# Check redirector user
 username=$1
 if [ ! -z "`$CAT /etc/passwd | $GREP $username`" ]; then
  $ECHO "1"
 else
  $ECHO "0"
 fi
}

check_clean ()
{
# Check that everything is clean before we start
 if [ -f  $WORK_DIR/$LIST_NAME ]; then
  $PRINTF "Old blacklist file found in ${WORK_DIR}..."
  $RM $WORK_DIR/$LIST_NAME
  $ECHO "Deleted."
 fi
}

set_permission ()
{
# Setting files permissions
 if [ "`checkuser $RDR_USER`" = "1" ]; then
  $PRINTF "\nSetting files permissions..."
  $CHOWN -R $RDR_USER:$RDR_GROUP $BASE3
  $CHMOD 755 $BASE3
  cd $BASE3
  $FIND . -type f -exec $CHMOD 644 {} \;
  $FIND . -type d -exec $CHMOD 755 {} \;
 else
  $ECHO "ERROR: User $RDR_USER does not exists. Exiting..."
  exit 5
 fi
}

download_list ()
{
 # Make working directory
 if [ ! -d $WORK_DIR ]; then
  $PRINTF "Make working directory..."
  $MKDIR -p $WORK_DIR
  $ECHO "Done."
 fi
 # Get list from one server using server list
 $PRINTF "List downloading..."
 for S in $SERVER_LIST; do
  $WGET -T $TIMEOUT -q -O $WORK_DIR/$LIST_NAME $S
  retcode=`$ECHO $?`
  case "$retcode" in
   0)
    $ECHO "List downloaded successfully."
    break
   ;;
   4)
    $ECHO "Unable to resolve host address. Exiting..."
    exit 4
   ;;
   *)
    $ECHO "Error downloading list from `$ECHO $S|$CUT -f1 -d '/'`. Try another server..."
    continue
   ;;
  esac
 done

 if [ "$retcode" != "0" ]; then
  $ECHO "Error downloading list from all servers. Exiting..."
  exit 1
 fi

 # If destination directory not exists, lets create it
 if [ ! -d "$DIR_CUSTOM2" ]; then
  $MKDIR -p $DIR_CUSTOM2
 fi

 # List transformation
 $GZCAT $WORK_DIR/$LIST_NAME | $TAIL -n +2 | $AWK -F',' '{ print $2 }'| $SED -e 's/"//' | $SED -e 's/^https\?:\/\///' | $SORT | $UNIQ -u > $DIR_CUSTOM2/domains
 # Update time for file
 $TOUCH $DIR_CUSTOM2/domains
 # Set permissions
 set_permission
}

clean_up ()
{
# Clean up file and directories
 $PRINTF "Clean up downloaded file and directories..."
 $RM -rf $WORK_DIR
 $ECHO "Done."
}

##############
# Main block #
##############

# Root check
root_check

# Check working directory clean
check_clean

# Download list
download_list

# Clean up
clean_up

exit 0
#####