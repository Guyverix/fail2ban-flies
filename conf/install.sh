#!/usr/bin/env bash

#Attempt to make a valid config and env

canonicalpath=`readlink -f $0`
canonicaldirname=`dirname ${canonicalpath}`/..
samedirname=`dirname ${canonicalpath}`


if [[ $(whoami) != 'root' ]]; then
  echo "This script must be run as root"
  exit 0
fi

# Verify that fail2ban is already running
RUNNING=$(ps uax | grep -c "fail2ban-server")
if [[ ${RUNNING} -lt 1 ]]; then
  echo 'Make sure that fail2ban is already running.'
  echo 'This ensures that fail2ban is at least minimally working already.'
  exit 1
else
  echo "Confirmed fail2ban-server is runnning"
fi

SANITY=$(fail2ban-client status | grep -c "fail2ban-flies")
if [[ ${SANITY} -ne 0 ]];then
  echo ""; echo ""
  echo "I see that fail2ban-flies is already installed."
  echo "Oops.  I am not screwing up an installation"
  exit 0
fi

echo "Installing action.d file"
cp ../fail2ban/action.d/fail2ban-flies.conf /etc/fail2ban/action.d/
# Create root path var and set it in the action file
ROOT_DIR=$(echo "${canonicaldirname}" | sed 's|/..||g')
echo "Update new action filter with pathing"
sed -i -- "s|CHANGEME|${ROOT_DIR}|g" /etc/fail2ban/action.d/fail2ban-flies.conf

echo "Installing filter.d file"
echo "NOTE: This is not needed currently.  Stub file only"
cp ../fail2ban/filter.d/fail2ban-flies.conf /etc/fail2ban/filter.d/

# see if we we have tried an install before
PREVIOUS=$(grep -c "fail2ban-flies" /etc/fail2ban/jail.local)
if [[ ${PREVIOUS} -eq 0 ]]; then
  echo "Updating the jail.local file"
  echo "If there are errs, your origional file is saved as jail_bak"
  cp /etc/fail2ban/jail.local /etc/fail2ban/jail_bak
  cat ../fail2ban/jail/flies-jail.local >> /etc/fail2ban/jail.local
else
  echo "Appears that the install has been run before"
  echo "Not going to make things worse by doing it again"
  echo "Check the config against ../fail2ban/jail/flies-jail.local if you have trouble"
fi

echo "Make sure things are sane"
fail2ban-client reload

echo "confirm that the new jail is in place"
CHECK=$(fail2ban-client status | grep -c "fail2ban-flies")
if [[ ${CHECK} -lt 1 ]]; then
  echo "Appears that new jail was not installed properly"
  echo "Attempting daemon reload"
  sudo service fail2ban reload
  CHECK=$(fail2ban-client status | grep -c "fail2ban-flies")
  if [[ ${CHECK} -lt 1 ]]; then
    echo "Appears that new jail was not installed properly"
    echo "Unable to repair via automation, sorry."
    echo "Reverting changes on your jail.local file"
    mv /etc/fail2ban/jail.local /etc/fail2ban/jail_failed
    mv /etc/fail2ban/jail_bak /etc/fail2ban/jail.local
    service fail2ban reload
    exit 2
  else
    echo "Appears jail updated on retry"
  fi
else
  echo "fail2ban-flies jail is updated"
fi

echo "Installing systemd daemon"
cat ./fail2ban-flies.systemd | sed  "s|/opt/CHANGEME|${ROOT_DIR}|g" > /etc/systemd/system/fail2ban-flies.systemd

echo "systemctl reload"
systemctl reload

echo "systemctl enable"
systemctl enable fail2ban-flies

echo "Start daemon"
service fail2ban-flies start
