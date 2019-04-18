# fail2ban-flies
scripts to have jailed IP addresses propagate to remote hosts

This is still in the basic spitball state.  What I am writing will require ssh and sudo privs at the minimum for the fail2ban update.  The plan is when fail2ban jails a bad IP, and runs the execute script, the script will ssh to hosts given in a config file and run the fail2ban ban IP setting for a given jail.  In  this way attacks across the infrastructure will stop faster, and all hosts will have a kind of eventual consistency.  Also given the eventual age-out of a jail no effort needs to be applied once enough time passes. 

The script will be written in bash and have at minimum one helper file with a list of peer IP addresses.

The script will be called something like: <script> -J <JAIL> -I w.X.y.Z 
As a safety, likely a -U will be added so we can manually Unban across a fleet from a single host as well.  This should keep friendlies from getting too annoyed when they get banned for doing something dumb.

The script will require either a password (bad idea, but it is your network) or ssh-keys to be set up.
The sudoers file will need at least a passwordless setting for the fail2ban-client so the user can update the jail.

Log levels will be set internal to the script or possibly by the cfg file to log to syslog

Since I am spitballing this, another switch -W (web) will be coded in so that instead of sshing to all the hosts, it will do a web reqeust to a web-server that will make the update to the other machines.  This may make things easier for users where ssh between hosts on a network is problematic and need only a single host  somewhere to do the updates.
