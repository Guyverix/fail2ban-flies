#!/bin/bash -
#===============================================================================
#
#          FILE: fail2ban-flies.sh
#
#         USAGE: ./fail2ban-flies.sh options
#
#   DESCRIPTION: 
#
#  REQUIREMENTS: ---
#        AUTHOR: Christopher Hubbard (CSH), guyverix@yahoo.com
#  ORGANIZATION: Personal
#       CREATED: 04/18/2019 03:50:41 PM
#===============================================================================


# set -o nounset  # Treat unset variables as an error
canonicalpath=`readlink -f $0`
canonicaldirname=`dirname ${canonicalpath}`/..
samedirname=`dirname ${canonicalpath}`

#==============================================================================
# Define a base useage case for a -h option
#==============================================================================
usage(){
cat << EOF
Usage: $0 options

This script is intended to be called to update other fail2ban hosts with a new
ban defined for a given Jail.

Options:
-h  show this help screen
-x  enable debug mode
-J  Jail name we are working with
-I  IP address we are working with
-U  Unban an IP from Jail
-W  Run in HTTP mode
-C  Config file we are using (if not ./ipList.cfg)

Example:
$0 -J ssh -I 8.8.8.8 
Status OK - Remote host(s) have been updated
Or
Status ERROR - Not all remote host(s) took the update

EOF
}

# Set sane defaults
JAIL='recdive'
CFG="./ipList.cfg"
WEB='false'
UNBAN='false'

while getopts "hxUWJ:I:C:" OPTION
do
  case ${OPTION} in
    h) usage; exit 0    ;;
    x) export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; set -x ;;
    U) UNBAN='true'     ;;
    W) WEB='true'       ;;
    J) JAIL="${OPTARG}" ;;
    I) IP="${OPTARG}"   ;;
    C) CFG="${OPTARG}"  ;;
    *) echo "Status FATAL - Unexpected argument given $@"; exit 2 ;;
  esac
done


