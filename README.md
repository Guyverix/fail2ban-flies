# fail2ban-flies
scripts to have jailed IP addresses propagate to remote hosts

The series of scripts are currently working at a basic level.  The bash version to use ssh/keys and login to remote hosts works.  However more error correction is needed with it.  The setup is a little too manual for my taste.

PYTHON: (receiver)
I am happy with the results so far.  This is a daemon that runs listening on a given port.  It has basic authentication in place to allow for security.  Internally it is running the Python webserver lcoked down.  I have removed POST and CGI information so only GET is allowed.  There is error correction to make this really only work with between one to three variables.  Using this does not require sudo as it will be running as a service under the root user account.  This seems the most reasonable way to deal with getting updates and not having to worry about ssh passwords or other possible headaches like that.

The Python daemon version does not have any logging as fail2ban itself will log bans.  Do not see a reason to duplicate this functionality.

An example for python would be calling http://<IP>:<PORT>/?ip=192.168.255.255&ban=banip (and authenticating)


BASH:

The bash script will require either a password (bad idea, but it is your network) or ssh-keys to be set up.

The sudoers file will need at least a passwordless setting for the fail2ban-client so the user can update the jail.

This still needs some work:

Log levels will be set internal to the script or possibly by the cfg file to log to syslog


TODO (if anyone cares about it)

Since I am spitballing this, another switch -W (web) will be coded in so that instead of sshing to all the hosts, it will do a web reqeust to a web-server that will make the update to the other machines.  This may make things easier for users where ssh between hosts on a network is problematic and need only a single host  somewhere to do the updates.

Initial commits have been done with the basic logic for the bash script, however it is a save point and nothing has been tested yet.  Logging has been put in place that supports syslog or a local log file.  However the local logfile is using Linux specific vars and will cause Mac's to have heart-burn.  I will alter that later once I have the Linux version working correctly.

The logic is now in place for verification of sshpass existing, as that will be necessary when using a password based login.  I am unsure if Mac's have the same script available but will cross that bridge when I come to it.

There is a basic web post curl statement using GET as well as a second one for POST.  The intial PHP version will likely only support GET since it is simpler and we are not dealing with sensitive information.
