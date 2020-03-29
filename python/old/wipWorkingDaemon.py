#!/usr/bin/env python3

import http.server
import cgi
import base64
import json
import os
import subprocess
from urllib.parse import urlparse, parse_qs

# This is our config file
# parsable via bash OR python
# USE CAUTION

from webserver import *

# Set our variables here
PORT = 3333
USERNAME='changeme'
USERPASS='test'

class CustomServerHandler(http.server.BaseHTTPRequestHandler):

    def do_HEAD(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_AUTHHEAD(self):
        self.send_response(401)
        self.send_header(
            'WWW-Authenticate', 'Basic realm="Demo Realm"')
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_GET(self):
        key = self.server.get_auth_key()

        ''' Present frontpage with user authentication. '''
        if self.headers.get('Authorization') == None:
            self.do_AUTHHEAD()

            response = {
                'success': False,
                'error': 'No auth header received'
            }

            self.wfile.write(bytes(json.dumps(response), 'utf-8'))

#       This is where the majority of the logic resides
#       Do not allow slop.  Either we have EXACTLY what we need
#       or defaults cover it.  Do not allow for easily
#       exploitable weaknesses

        elif self.headers.get('Authorization') == 'Basic ' + str(key):
            getvars = self._parse_GET()
            keys = getvars.keys()
            values = getvars.values()
            failed = 'false'

            try:
                jailList = getvars.get('jail')
                httpJail = ''.join(jailList)
            except:
                httpJail = str(jail)

            try:
                banList = getvars.get('ban')
                httpBan = ''.join(banList)
            except:
                httpBan = str(ban)

#           We only support banip and unbanip for safety
#           412 is precondition failed
            if httpBan not in ["banip","unbanip"]:
                self.send_response(412)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                failed = 'true'
                response = {
                    'manditory_parameter': "ban= only supports banip and unbanip"
                }

            try:
                ipList = getvars.get('ip')
                httpIp = ''.join(ipList)
            except:
                self.send_response(412)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                failed = 'true'
                response = {
                    'manditory_parameter': "ip=w.x.y.z is manditory"
                }

#           If we have what we need, do something now
#           HTTP 202 is accepted
            if failed != 'true':
                command = 'fail2ban-client set ' + httpJail + ' ' + httpBan + ' ' + httpIp
                self.send_response(202)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
 #               os.system(command)
                command2 = ["fail2ban-client", "set", httpJail, httpBan, httpIp]
#                runUpdate = subprocess.run(["fail2ban-client", "set", httpJail, httpBan, httpIp],shell=true)
#                runUpdate = subprocess.getoutput(command2,shell=True)
                runUpdate = subprocess.Popen(command,shell=True, stdout=subprocess.PIPE)
                (runUpdateOutput, err) = runUpdate.communicate()
                runUpdate_status = runUpdate.wait()
                response = {
                    'path': self.path,
                    'get_vars': str(getvars),
                    'conf_default_ban': str(ban),
                    'conf_default_jail': str(jail),
                    'conf_default_PORT': str(PORT),
                    'conf_default_USERNAME': str(USERNAME),
                    'conf_default_USERPASS': str(USERPASS),
                    'os_command': str(command),
                    'subprocess_command': str(command2),
                    'subprocess_status': str(runUpdate_status),
                    'subprocess_output': str(runUpdateOutput),
                    'keys': str(keys),
                    'values': str(values),
                    'runUpdate': str(runUpdate)
                }
#           Even on a fatal error never give too much data
#           when dealing with security "things"
            else:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {
                    'error': "An unexpected error occured.  No further details available"
                }

# This stuff should be removed or completely disable
#            base_path = urlparse(self.path).path
#            if base_path == '/path1':
#                # Do some work
#                pass
#            elif base_path == '/path2':
#                # Do some work
#                pass

#            self.wfile.write(bytes(json.dumps(response), 'utf-8'))
#        else:
#            self.do_AUTHHEAD()

#            response = {
#                'success': False,
#                'error': 'Invalid credentials'
#            }

            self.wfile.write(bytes(json.dumps(response), 'utf-8'))

    ''' There is no reason currently to support
        POST so we are going to simply ignore this but
        keep it stubbed just in case '''
    def do_POST(self):
        key = self.server.get_auth_key()

        ''' Present frontpage with user authentication. '''
        if self.headers.get('Authorization') == None:
            self.do_AUTHHEAD()

            response = {
                'success': False,
                'error': 'No auth header received'
            }

            self.wfile.write(bytes(json.dumps(response), 'utf-8'))

        elif self.headers.get('Authorization') == 'Basic ' + str(key):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            postvars = self._parse_POST()
            getvars = self._parse_GET()

            response = {
                'path': self.path,
                'get_vars': str(getvars),
                'get_vars': str(postvars)
            }

            base_path = urlparse(self.path).path
            if base_path == '/path1':
                # Do some work
                pass
            elif base_path == '/path2':
                # Do some work
                pass

            self.wfile.write(bytes(json.dumps(response), 'utf-8'))
        else:
            self.do_AUTHHEAD()

            response = {
                'success': False,
                'error': 'Invalid credentials'
            }

            self.wfile.write(bytes(json.dumps(response), 'utf-8'))

        response = {
            'path': self.path,
            'get_vars': str(getvars),
        }

        self.wfile.write(bytes(json.dumps(response), 'utf-8'))

    def _parse_POST(self):
        ctype, pdict = cgi.parse_header(self.headers.getheader('content-type'))
        if ctype == 'multipart/form-data':
            postvars = cgi.parse_multipart(self.rfile, pdict)
        elif ctype == 'application/x-www-form-urlencoded':
            length = int(self.headers.getheader('content-length'))
            postvars = cgi.parse_qs(
                self.rfile.read(length), keep_blank_values=1)
        else:
            postvars = {}

        return postvars

    def _parse_GET(self):
        getvars = parse_qs(urlparse(self.path).query)

        return getvars


class CustomHTTPServer(http.server.HTTPServer):
    key = ''

    def __init__(self, address, handlerClass=CustomServerHandler):
        super().__init__(address, handlerClass)

    def set_auth(self, username, password):
        self.key = base64.b64encode(
            bytes('%s:%s' % (username, password), 'utf-8')).decode('ascii')

    def get_auth_key(self):
        return self.key


if __name__ == '__main__':
    server = CustomHTTPServer( ('', PORT))
    server.set_auth(USERNAME, USERPASS)
    server.serve_forever()

    import time
    import systemd.daemon

    print('Starting up ...')
    time.sleep(10)
    print('Startup complete')
    systemd.daemon.notify('READY=1')

    while True:
        print('heartbeat for fail2ban-flies')
        time.sleep(5)
