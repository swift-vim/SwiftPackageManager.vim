from threading import Thread
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import SocketServer
import vim
import subprocess
import os
import socket
import traceback
import tempfile


# Utils

def CreateLogfile(prefix=''):
    with tempfile.NamedTemporaryFile(prefix=prefix,
                                     suffix='.log',
                                     delete=False) as logfile:
        return logfile.name


def VimToPythonType(result):
    if not (isinstance(result, str) or isinstance(result, bytes)):
        return result

    try:
        return int(result)
    except ValueError:
        return ToUnicode(result)


def ToUnicode(value):
    if not value:
        return str()
    if isinstance(value, str):
        return value
    if isinstance(value, bytes):
        # All incoming text should be utf8
        return str(value, 'utf8')
    return str(value)


class HTTPRequestHandler(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        # Status check
        self._set_headers()
        self.wfile.write('true')

    def do_POST(self):
        try:
            self._run_POST()
        except Exception, e:
            traceback.print_exc()

    def _run_POST(self):
        # Main API
        # /e evaluate an expression
        # /c execute a command
        self._set_headers()
        content_len = int(self.headers.getheader('content-length', 0))
        post_body = self.rfile.read(content_len)
        # Consider putting this on a queue
        if self.path == '/e':
            value = VimToPythonType(vim.eval(post_body))
            if not value:
                value = ''
            self.wfile.write(value.encode('ascii'))
        elif self.path == '/c':
            value = VimToPythonType(vim.command(post_body))
            if not value:
                value = ''
            self.wfile.write(value.encode('ascii'))
        else:
            # FIXME: Send a failing code
            self.wfile.write('error: unknown path'.encode('ascii'))

    def log_message(self, format, *args):
        # Disable logging
        return


def GetEditorServicePath():
    path = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..',
                        '.build', 'debug', 'spm-vim')
    return path


def GetUnusedLocalhostPort():
    sock = socket.socket()
    # This tells the OS to give us any free port in the range [1024 - 65535]
    sock.bind(('', 0))
    port = sock.getsockname()[1]
    sock.close()
    return port


class Server():
    def __init__(self):
        # FIXME: determine dynamically
        self.port = GetUnusedLocalhostPort()

        self.http_server = HTTPServer(('', self.port), HTTPRequestHandler)
        self.http_thread = Thread(target=self._RunHttpServer)

        self.stdout_log = CreateLogfile('stdout')
        self.stderr_log = CreateLogfile('stderr')

        self.editor_service_path = GetEditorServicePath()
        self.editor_service_thread = Thread(target=self._RunEditorService)

    def Start(self):
        self.http_thread.start()
        self.editor_service_thread.start()

    def Stop(self):
        # Close the socket to shutdown the server immediately.
        # The default implementation takes too long to shutdown,
        # when vim is trying to exit.
        try:
            self.http_server.socket.close()
        except:
            pass
        finally:
            self.http_thread.join()

        try:
            self.editor_service.terminate()
        except:
            pass

    def PrintLogs(self):
        print("stdout: " + self.stdout_log)
        print("stderr: " + self.stderr_log)

    def _RunEditorService(self):
        with open(self.stdout_log, 'w') as out, open(self.stderr_log, 'w') as err:
            cmd = [self.editor_service_path,
                   'editor', 'TOK', '--port', str(self.port)]
            self.editor_service = subprocess.Popen(cmd, stdout=out)
            self.editor_service.communicate()

    def _RunHttpServer(self):
        try:
            self.http_server.serve_forever()
        except:
            pass
        finally:
            self.http_server.server_close()
