#!/usr/bin/env python3

import http.server
import cgi
import base64
import json
import os
import subprocess
from urllib.parse import urlparse, parse_qs

# Hard set our variables here for the config file
import sys
lib_path = os.path.abspath(os.path.join(__file__, '..','../conf'))
sys.path.append(lib_path)
from config import *

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

        elif self.headers.get('Authorization') == 'Basic ' + str(key):
            getvars = self._parse_GET()
            keys = getvars.keys()
            values = getvars.values()
            failed = 'false'

            try:
                jailList = getvars.get('jail')
                httpJail = ''.join(jailList)
            except:
                httpJail = str(JAIL)

            try:
                banList = getvars.get('ban')
                httpBan = ''.join(banList)
            except:
                httpBan = str(ban)

#           We only support banip and unbanip for safety
#           412 is precondition failed
            if httpBan not in ["banip","unbanip"]:
                failed = 'true'
                self.send_response(412)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {
                    'result': "failed",
                    'reason': "ban= supported values banip, unbanip"
                }
                self.wfile.write(bytes(json.dumps(response), 'utf-8'))

            try:
                ipList = getvars.get('ip')
                httpIp = ''.join(ipList)
            except:
                failed = 'true'
                self.send_response(412)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {
                    'result': "failed",
                    'reason': "ip=w.x.y.z is manditory"
                }
                self.wfile.write(bytes(json.dumps(response), 'utf-8'))

#           If we have what we need, do something now
#           HTTP 202 is accepted
            if failed != 'true':
                command = 'fail2ban-client set ' + httpJail + ' ' + httpBan + ' ' + httpIp
                runUpdate = subprocess.Popen(command,shell=True, stdout=subprocess.PIPE)
                (runUpdateOutput, err) = runUpdate.communicate()
                runUpdate_status = runUpdate.wait()
                if ( "is not banned" in str(runUpdateOutput)):
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    result = "success"
                    reason = "IP was not banned to begin with"
                elif ("Sorry" in str(runUpdateOutput)):
                    self.send_response(417)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    reason = "jail does not exist"
                    result = "failed"
                else:
                    result = "success"
                    reason = "good data"
                    self.send_response(202)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()

                response = {
                    'result': str(result),
                    'reason': str(reason),
                    'ip': str(httpIp)
                }
                self.wfile.write(bytes(json.dumps(response), 'utf-8'))
            elif (failed == 'true'):
#           We already gave data back.  Stub
#           for things like verbose results... Maybe
                foo = "var"

#           Even on a fatal error never give too much data
#           when dealing with security "things"
            else:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {
                    'result': "failed",
                    'path': self.path,
                    'get_vars': str(getvars),
                    'error': "An unexpected error occured.  No further details available"
                }
                self.wfile.write(bytes(json.dumps(response), 'utf-8'))

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
    if ( SSL == "true" ):
        import ssl
        server = CustomHTTPServer(('', PORT))
        server.set_auth(USERNAME, USERPASS)
        server.socket = ssl.wrap_socket (server.socket,
        keyfile="/etc/ssl/private/ssl-cert-snakeoil.key", 
        certfile='/etc/ssl/certs/ssl-cert-snakeoil.pem', server_side=True)
        server.serve_forever()
    else:
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
