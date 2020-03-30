# bash vars (TX)

# ssh vars
USER='chubbard'
PASS="somePassword"
KEY="/home/${USER}/.ssh/id_rsa"
AUTH='key'

# Hosts to update with ban list
# space delimited.  FQDN, or IP
REMOTE_IP="192.168.15.74 192.168.15.131 192.168.15.176 192.168.15.58 192.168.15.177 192.168.15.105"

# shared vars
# default jail if not explicitly given 
JAIL='fail2ban-flies'

# python daemon vars (RX)
# default action if not told otherwise
ban='unbanip'

# Daemon where port is listening
PORT=3333

# User auth for daemon to accept ban updates
USERNAME='changeme'
USERPASS='test'

# Server settings if SSL is to be supported
SSL='false'
CERT='/etc/ssl/certs/ssl-cert-snakeoil.pem'
SSLKEY='/etc/ssl/private/ssl-cert-snakeoil.key'
PYTHONDONTWRITEBYTECODE=1

# Unused currently (FUTURE MAYBE)
WEBSITE="http://webhost.some.domain.com/?ip="

