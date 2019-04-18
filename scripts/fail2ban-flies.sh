#!/bin/bash -
#===============================================================================
#
#          FILE: fail2ban-flies.sh
#
#         USAGE: ./fail2ban-flies.sh options
#
#   DESCRIPTION: Update remote fail2ban instances either directly or
#                indirectly
#  REQUIREMENTS: fail2ban, ssh, sudo
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

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  logger
#   DESCRIPTION:  Log to syslog and echo state
#    PARAMETERS:  globals
#       RETURNS:  stdout
#-------------------------------------------------------------------------------
logger () {

}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  webPush
#   DESCRIPTION:  Use curl and POST to a website
#    PARAMETERS:  globals
#       RETURNS:  logger and stdout before exit
#-------------------------------------------------------------------------------
webPush () {

}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hostSsh
#   DESCRIPTION:  ssh to remote hosts and update fail2ban
#    PARAMETERS:  globals
#       RETURNS:  logger and stdout before exit
#-------------------------------------------------------------------------------
hostSsh() {

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

# Confirm we have the information we need
if [[ -e ${CFG} ]];then
  . ${CFG}
else
  echo "Status FATAL - the IP configuration file is manditory, and not found"; exit 2
fi

if [[ -z ${IP} ]]; then
  echo "Status FATAL - an IP address is manditory"; exit 2
fi

# Decide what we are going to update
if [[ "${WEB}" = "true" ]];then
  webPush
else
  hostSsh
fi
exit 0

