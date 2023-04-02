#!/sbin/sh

# By accepting this notice, you agree to be bound by the following
# agreements:
#
# This script written by Yuri Voinov (C) 2010,2022
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
# ufdbGuard blocklist update
#
# Based on shalla_update.sh, v 0.3.1 20080403
# and update_blocklist.sh, v 1.1-1.9 by Y.Voinov.
#
# ident   "@(#)update_blocklist.sh     2.0     05/04/22 YV"
#

## NOTE: You can select redirector compilation categories by edit CATEGORIES variable for compilation.

#############
# Variables #
#############

# ------------- Blacklist options ------------------
CATEGORIES="adult arjel agressif audio-video celebrity cryptojacking dangerous_material dating ddos dialer drogue gambling games hacking lingerie malware manga mixed_adult phishing redirector remote-control sect sexual_education social_networks stalkerware warez"
# ------------- Blacklist options ------------------

# Modify PATH for SFW directory use
PATH=/usr/sfw/bin:$PATH

# List name
LIST_NAME="blacklists_for_pfsense.tar.gz"

# Servers for downloading blacklist
SERVER1="http://dsi.ut-capitole.fr/blacklists/download/$LIST_NAME"
SERVER2=""

SERVER_LIST="$SERVER1 $SERVER2"
TEMP_DIR="/tmp"
WORK_DIR="$TEMP_DIR/pfsense"

# Connection timeout for downloading
TIMEOUT=30

# SMF name
SMF_NAME="svc:/network/ufdbguard:default"

# Redirector user name
RDR_USER="ufdb"
RDR_GROUP="ufdb"

# Installation base dir
BASE="/usr/local"
# Redirector dir base
BASE2=$BASE"/ufdbguard"
# Redirector blacklist base
BASE3=$BASE2"/blacklists/BL"

# Redirector convert tool location
RDR_GUARD_DB_TOOL=$BASE2"/bin/ufdbConvertDB"
# Redirector daemon
RDR_BIN_FILE="ufdbguardd"

DIR_ALLOW=$BASE3"/alwaysallow"
DIR_DENY=$BASE3"/alwaysdeny"
DIR_CUSTOM=$BASE3"/yoyo"
DIR_CUSTOM2=$BASE3"/phishtank"
DIR_CUSTOM3=$BASE3"/miners"

# OS utilities
AWK=`which awk`
BASENAME=`which basename`
CAT=`which cat`
CD=`which cd`
CHOWN=`which chown`
CHMOD=`which chmod`
CP=`which cp`
CUT=`which cut`
ECHO=`which echo`
EXPRT=`which expr`
FIND=`which find`
GETOPT=`which getopt`
GREP=`which grep`
GZCAT=`which gzcat`
ID=`which id`
KILL=`which kill`
MKDIR=`which mkdir`
NEWTASK=`which newtask`
PRINTF=`which printf`
PS=`which ps`
RM=`which rm`
SVCADM=`which svcadm`
TOUCH=`which touch`
GTAR=`which gtar`
UNAME=`which uname`
WGET=`which wget`

###############
# Subroutines #
###############

usage_note ()
{
# Script usage note
 $ECHO "Usage: `$BASENAME $0` [-h][-f][-a]"
 $ECHO
 $ECHO "No args - default mode. Full update and recompilation."
 $ECHO "a - Ads & phishtank & always lists recompilation (whenever updated/exists or not)"
 $ECHO "f - full update and recompilation."
 $ECHO "h - this screen."
 $ECHO "Beware: Categories with .notused file in dir will never be compiled."
 exit 0
}

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
 if [ -f  $WORK_DIR/$LIST_NAME -o -f $WORK_DIR/*.tar ]; then
  $PRINTF "Old blacklist file found in ${WORK_DIR}..."
  $RM $WORK_DIR/*pfsense.*
  $ECHO "Deleted."
 fi

 if [ -d $WORK_DIR ]; then
  $PRINTF "Old blacklist directory found in ${WORK_DIR}..."
  $RM -rf $WORK_DIR
  $ECHO "Deleted."
 fi
}

download_ads ()
{
 # If Yoyo adblock script exists, run it first
 [ -x $BASE/bin/create_filter_ad_servers.sh ] && $ECHO "Ads download script exists." && $BASE/bin/create_filter_ad_servers.sh
}

download_phishtank ()
{
 # If Phishtank script exists, run it first
 [ -x $BASE/bin/update_phishtank.sh ] && $ECHO "Phishtank download script exists." && $BASE/bin/update_phishtank.sh
}

download_miners ()
{
 # If miners script exists, run it first
 [ -x $BASE/bin/update_miners.sh ] && $ECHO "Miners download script exists." && $BASE/bin/update_miners.sh
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
 $PRINTF "Black list downloading..."
 for S in $SERVER_LIST; do
  $WGET -T $TIMEOUT -q -O $WORK_DIR/$LIST_NAME $S
  retcode=`$ECHO $?`
  case "$retcode" in
   0)
    $ECHO "Black list downloaded successfully."
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
}

compile_always ()
{
# Compile alwaysallow & alwaysdeny & custom databases if they exists
 $PRINTF "Compile always and custom databases..."
 if [ -d $DIR_ALLOW ]; then
  $PRINTF "allow exists..."
  $RDR_GUARD_DB_TOOL -d $DIR_ALLOW >/dev/null 2>&1
  $PRINTF "Done..."
 fi

 if [ -d $DIR_DENY ]; then
  $PRINTF "deny exists..."
  $RDR_GUARD_DB_TOOL -d $DIR_DENY >/dev/null 2>&1
  $PRINTF "Done..."
 fi

 if [ -d $DIR_CUSTOM ]; then
  $PRINTF "custom exists..."
  $RDR_GUARD_DB_TOOL -d $DIR_CUSTOM >/dev/null 2>&1
  $PRINTF "Done..."
 fi

 if [ -d $DIR_CUSTOM2 ]; then
  $PRINTF "custom 2 exists..."
  $RDR_GUARD_DB_TOOL -d $DIR_CUSTOM2 >/dev/null 2>&1
  $PRINTF "Done..."
 fi

 if [ -d $DIR_CUSTOM3 ]; then
  $PRINTF "custom 3 exists..."
  $RDR_GUARD_DB_TOOL -d $DIR_CUSTOM3 >/dev/null 2>&1
  $PRINTF "Done..."
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

fast_list_compilation ()
{
 # First download ads if script exists
 download_ads
 # Then download phishtank if script exists
 download_phishtank
 # Then download miners if script exists
 download_miners
 # Ads & phishtank & miners & always lists compilation if they exists
 $PRINTF "Ads & phishtank & miners & always lists compilation only..."
 compile_always
 # Set files permissions
 set_permission
 $ECHO "Done."
}

full_list_compilation ()
{
 # First download ads if script exists
 download_ads
 # Then download phishtank if script exists
 download_phishtank
 # Then download miners if script exists
 download_miners
 # Then download blocklist
 download_list
 # Unpack list
 $PRINTF "List unpacking..."
 $GZCAT $WORK_DIR/$LIST_NAME | $GTAR -x -C $WORK_DIR
 $CP -rp $WORK_DIR/blacklists/* $BASE3
 $ECHO "Done."
 # Call recompilation for categories defined in list
 $PRINTF "Databases compiling..."
 for cat in $CATEGORIES
 do
  # Update date and time to current to be compiled
  $TOUCH $BASE3/${cat}/domains >/dev/null 2>&1
  $TOUCH $BASE3/${cat}/urls >/dev/null 2>&1
  $RDR_GUARD_DB_TOOL -d $BASE3/${cat} >/dev/null 2>&1
 done
 $ECHO "Done."
 compile_always
 # Set files permissions
 set_permission
 $ECHO "Done."
}

reconfiguration ()
{
 os=`$UNAME`
 if [ "$os" = "SunOS" ]; then
  $PRINTF "Redirector daemon restart..."
  # Redirector restart on Solaris-based boxes
  $SVCADM -v restart $SMF_NAME
 else
  $PRINTF "Redirector daemon reconfiguration..."
  # Redirector reconfiguration
  program=$1
  pid=`$PS -ef|$GREP $program|$GREP -v grep|$AWK '{ print $2 }'`
  $KILL -HUP $pid
 fi;
 $ECHO "Done."
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

# Check clean working dir
check_clean

# BL download, unpack and compilation
# Check command-line arguments
if [ "x$*" = "x" ]; then
# If arguments list empty, make compilation by default
 full_list_compilation
else
 arg_list=$*
 # Parse command line
 set -- `$GETOPT aAfFhH: $arg_list` || {
  usage_note 1>&2
 }

  # Read arguments
 for i in $arg_list
  do
   case $i in
    -a | -A) fast_list_compilation;;
    -f | -F) full_list_compilation;;
    -h | -H | \?) usage_note;;
   esac
   break
  done

 # Remove trailing --
 #shift `$EXPR $OPTIND - 1`
fi

# Redirector reconfiguration
reconfiguration $RDR_BIN_FILE

# Finally cleanup all downloaded files
clean_up

exit 0
#