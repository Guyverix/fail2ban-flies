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
#       VERSION: 0.0.1
#      REVISION: Cathy
#===============================================================================

# set -o nounset  # Treat unset variables as an error
# Remember that Mac does not like these.  Disable if they cause trouble
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
-P  Password passed via commandline *(not a good idea kids)
-S  disable using syslog
-T  test via ssh if the jail exists or not

Example:
$0 -J ssh -I 8.8.8.8 
Status OK - Remote host(s) have been updated
Or
Status ERROR - Not all remote host(s) took the update

EOF
}

#===  FUNCTION  ================================================================
#          NAME:  verify_deps
#   DESCRIPTION:  Check that all binary files are available to be used
#    PARAMETERS:  None.  This is standalone.  Changes occur on case by case
#       RETURNS:  none
#===============================================================================
syslogSeverity() {

# VALID SYSLOG VALUES
#emerg
#alert
#crit
#err
#warning
#notice
#info
#debug
local RAW=$1
case ${RAW} in
  DEB*) RET="debug"   ;;
  INF*) RET="info"    ;;
  FAT*) RET="emerg"   ;;
  WAR*) RET="warning" ;;
  ERR*) RET="err"     ;;
  *)    RET="debug"   ;;
esac
echo "${RET}"
}

#===  FUNCTION  ================================================================
#          NAME:  verify_deps
#   DESCRIPTION:  Check that all binary files are available to be used
#    PARAMETERS:  None.  This is standalone.  Changes occur on case by case
#       RETURNS:  none
#===============================================================================
verify_deps() {
if [[ "${AUTH}" != "key" ]] && [[ "${WEB}" != "true" ]];then
  needed="ssh sshpass"
elif [[ "${WEB}" == "true" ]];then
  needed="curl"
else
  # We cant tell what we might need check everything
  needed="ssh curl sshpass"
fi

# Loop through all the binaries and confirm they exist
# Unsure if this will work on a Mac properly or not
for i in `echo $needed`; do
  type $i >/dev/null 2>&1
  if [ $? -eq 1 ]; then
    echo "Status FATAL - missing manditory component: $i"; exit 2
  fi
done
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  local_logger
#   DESCRIPTION:  Log to logfile and echo state
#    PARAMETERS:  globals
#       RETURNS:  stdout
#-------------------------------------------------------------------------------
local_logger () {
# "Message" "ERR, or UOW" "Context id"

local MESSAGE=${1}
   if [ -z ${2} ];then
     # If there is no var 2, then this is NOT an error or UOW of some kind.
     local LOGGING="INFO"
     local CONTEXT1=${RANDOM}
   else
      local LOGGING="${2}"
      if [ -z ${3} ];then
         local CONTEXT1=${RANDOM}
      else
         local CONTEXT1="${3}"
      fi
   fi

   if [[ ${SYSLOG} ]]; then
     LOGGING=$(syslogSeverity "${LOGGING}")
     logger -t fail2ban-flies -p auth.${LOGGING} "${MESSAGE}"
   else
     # canonicaldirname does NOT work on Mac.  Find a better option
     LOGFILE="${canonicaldirname}/logs/`date +%F`_fail2ban-flies.log"
     touch ${LOGFILE}
     chmod 664 ${LOGFILE}

     local APP_NAME=`echo $0 | awk -F'/' '{print $NF}'`
     echo "\"$(date +%s%N)\": [[\"$(date -u +%FT%H:%M:%S)\", \"${LOGGING}\", \"$(hostname)\", \"${APP_NAME}\", \"$$\", \"${CONTEXT1}\"], {\"Event\":\"${MESSAGE}\"}]," >> ${LOGFILE}
   fi
}

# Begin the log file so JSON is vaild
beginlog() {
   local LOGGING="INFO"
   if [[ ${SYSLOG} ]]; then
      LOGGING=$(syslogSeverity "${LOGGING}")
      logger -t fail2ban-flies -p auth.${LOGGING} "${MESSAGE}"
   else
      LOGFILE="${canonicaldirname}/logs/`date +%F`_fail2ban-flies.log"
      touch ${LOGFILE}
      chmod 664 ${LOGFILE}
      echo '{' >> ${LOGFILE}
   fi
}

# Close the JSON properly
endlog() {
  local MESSAGE=${1}
  # "Message" "ERR, or UOW" "Context id"
  if [ -z ${2} ];then
    # If there is no var 2, then this is NOT an error or UOW of some kind.
    local LOGGING="INFO"
    local CONTEXT1=${RANDOM}
  else
    local LOGGING="${2}"
    if [ -z ${3} ];then
      local CONTEXT1=${RANDOM}
    else
      local CONTEXT1="${3}"
    fi
  fi

  if [[ ${SYSLOG} ]]; then
    LOGGING=$(syslogSeverity "${LOGGING}")
    logger -t fail2ban-flies -p auth.${LOGGING} "${MESSAGE}"
  else
    LOGFILE="${canonicaldirname}/logs/`date +%F`_fail2ban-flies.log"
    touch ${LOGFILE}
    chmod 664 ${LOGFILE}
    local APP_NAME=`echo $0 | awk -F'/' '{print $NF}'`
    echo "\"$(date +%s%N)\": [[\"$(date -u +%FT%H:%M:%S)\", \"${LOGGING}\", \"$(hostname)\", \"${APP_NAME}\", \"$$\", \"${CONTEXT1}\"], {\"Event\":\"${MESSAGE}\"}]" >> ${LOGFILE}
    echo '}' >> ${LOGFILE}
  fi
}

# Fatal errors follow the endlog function
fatal() {
endlog $[@]
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  webPush
#   DESCRIPTION:  Use curl and POST to a website
#    PARAMETERS:  globals
#       RETURNS:  logger and stdout before exit
#-------------------------------------------------------------------------------
webPush () {
# This will end up in cfg file later
local VERS='get'

#PORT = 3333
#USERNAME='changeme'
#USERPASS='test'


for REMOTE in ${REMOTE_IP} ; do
  if [[ ${VERS} == "get" ]];then
    # GET VERSION
    local WEB_PUSH=$(curl -u ${USERNAME}:${USERPASS} --connect-timeout 2 --max-time 25 -s -L "http://${REMODE}:${PORT}/?jail=${JAIL}&ip=${IP}&ban=${UNBAN}" -s -o /dev/null -w "%{http_code}" )
  else
    # POST VERSION
    local WEB_PUSH=$(curl --connect-timeout 2 --max-time 5 -X POST --data-urlencode "payload={\"jail\": \"${JAIL}\", \"ip\": \"${IP}\", \"ban\": \"${UNBAN}\"}" -s -o /dev/null -w "%{http_code}")
  fi

  # Log the results of our work
  if [[ $? -gt 0 ]]; then
    local_logger "${WEB_PUSH}" "ERROR"
  else
    local_logger "Pushed to webhost successfully" "DEBUG"
  fi
done
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  hostSsh
#   DESCRIPTION:  ssh to remote hosts and update fail2ban
#    PARAMETERS:  globals
#       RETURNS:  logger and stdout before exit
#-------------------------------------------------------------------------------
hostSsh() {
# Yes, this could be done much nicer, but I want it clear what is being done for V1
  if [[ "${AUTH}" == key ]]; then
    for REMOTE in ${REMOTE_IP} ; do
      # validate we are not attempting a localhost update
      if [[ "${LOCALIP}" =~ ${REMOTE} ]]; then
        local_logger "Status found local IP address match between ${REMOTE} and ${LOCALIP}.  Ignoring this update" "DEBUG"
      else
        local_logger "Using address ${REMOTE}" "DEBUG"
        SSH=$(ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${REMOTE} "sudo fail2ban-client set ${JAIL} ${UNBAN} ${IP}")
        if [[ $(echo "${SSH}" | grep -c "NOK\|Sorry") -gt 0 ]]; then
          local_logger "FAILURE: ${SSH} remote: ${REMOTE}" "ERROR"
        else
          local_logger "Updated ${REMOTE} host successfully to ${UNBAN} IP ${IP}" "DEBUG"
        fi
      fi
    done
  else
    for REMOTE in ${REMOTE_IP} ; do
      # validate we are not attempting a localhost update
      if [[ "${LOCALIP}" =~ ${REMOTE} ]]; then
        local_logger "Status found local IP address match between ${REMOTE} and ${LOCALIP}.  Ignoring this update" "DEBUG"
      else
        local_logger "Using address ${REMOTE}" "DEBUG"
        SSH=$(sshpass -p "${PASS}" ssh -o StrictHostKeyChecking=no ${USER}@${REMOTE} "sudo fail2ban-client set ${JAIL} ${UNBAN} ${IP}")
        if [[ $(echo "${SSH}" | grep -c "NOK\|Sorry") -gt 0 ]]; then
          local_logger "FAILURE: ${SSH} remote: ${REMOTE}" "ERROR"
        else
          local_logger "Updated ${REMOTE} host successfully to ${UNBAN} IP ${IP}" "DEBUG"
        fi
      fi
    done
  fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  testHosts
#   DESCRIPTION:  ssh to remote hosts and vailate they can work
#    PARAMETERS:  globals
#       RETURNS:  logger and stdout before exit
#-------------------------------------------------------------------------------
testHosts() {
  if [[ "${AUTH}" == key ]]; then
    for REMOTE in ${REMOTE_IP} ; do
      if [[ "${LOCALIP}" =~ ${REMOTE} ]]; then
        local_logger "Status found local IP address match between ${REMOTE} and ${LOCALIP}.  Ignoring this update" "DEBUG"
        echo "Found local IP address in checks.  Ignoring ${REMOTE}"
      else
        local_logger "Using address ${REMOTE}" "DEBUG"
        SSH=$(ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${REMOTE} "sudo fail2ban-client status | grep -c ${JAIL} ")
        if [[ ${SSH} -lt 1 ]]; then
          echo "Failure: failed to find jail ${JAIL} on remote host ${REMOTE}"
        else
          echo "Success: found jail ${JAIL} on remote host ${REMOTE}"
        fi
      fi
    done
  else
    for REMOTE in ${REMOTE_IP} ; do
      SSH=$(sshpass -p "${PASS}" ssh -o StrictHostKeyChecking=no ${USER}@${REMOTE} "sudo fail2ban-client status | grep -c ${JAIL}")
      if [[ ${SSH} -lt 1 ]]; then
        echo "Failure: failed to find jail ${JAIL} on remote host ${REMOTE}"
      else
        echo "Success: found jail ${JAIL} on remote host ${REMOTE}"
      fi
    done
  fi
}

# Set sane defaults
#JAIL='fail2ban-flies'
JAIL='recidive'
CFG="${samedirname}/ipList.cfg"
WEB='false'
UNBAN='banip'
USER=$(whoami)
SYSLOG="true"
PASS=''
TEST='false'

while getopts "hxUWTSJ:I:C:P:" OPTION
do
  case ${OPTION} in
    h) usage; exit 0    ;;
    x) export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; set -x ;;
    U) UNBAN='unbanip'       ;;
    W) WEB='true'       ;;
    P) PASS="${OPTARG}" ;;
    J) JAIL="${OPTARG}" ;;
    I) IP="${OPTARG}"   ;;
    S) SYSLOG="false"   ;;
    T) TEST='true'      ;;
    C) CFG="${OPTARG}"  ;;
    *) echo "Status FATAL - Unexpected argument given $@"; exit 2 ;;
  esac
done

# Confirm we have the information we need
verify_deps

# Find our local machine IP address now
LOCALIP=$(hostname -I)

# Load the configuration file
if [[ -e ${CFG} ]];then
  . ${CFG}
else
  echo "Status FATAL - the IP configuration file is manditory, and not found"; exit 2
fi

if [[ -z ${REMOTE_IP} ]]; then
  echo "Status FATAL - an IP address is manditory"; exit 2
fi

# Testing validation here
if [[ ${TEST} = true ]];then
  testHosts
  exit 0
fi

# Begin logging
if [[ ${SYSLOG} ]]; then
  logger -t fail2ban-flies "beginning fail2ban-flies push"
else
  # beginLog does not take args
  beginLog
  local_logger "beginning fail2ban-flies push" "DEBUG"
fi

# Decide what we are going to update
if [[ "${WEB}" = "true" ]];then
  local_logger "fail2ban-flies using web services" "DEBUG"
  webPush
else
  local_logger "fail2ban-flies using ssh services" "DEBUG"
  hostSsh
fi

# Update our logs
if [[ ${SYSLOG} ]]; then
  logger -t fail2ban-flies "ending fail2ban-flies push"
else
  endLog "ending fail2ban-flies push"
fi

exit 0



