from threading import Thread
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import SocketServer
import vim
import subprocess
import os
import socket

class HTTPRequestHandler(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        # Status check
        self._set_headers()
        self.wfile.write("true")
        
    def do_POST(self):
        # Main API
        # /e evaluate an expression
        # /c execute a command
        self._set_headers()
        content_len = int(self.headers.getheader('content-length', 0))
        post_body = self.rfile.read(content_len)
        if self.path == "/e":
            value = vim.eval(post_body)
            self.wfile.write(value)
        elif self.path == "/c":
            value = vim.command(post_body)
            self.wfile.write(value)
        else:
            # FIXME: Send a failing code
            self.wfile.write("error: unknown path")

    def log_message(self, format, *args):
        # Disable logging
        return


def GetEditorServicePath():
    path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..",
            ".build", "debug", "spm-vim")
    return path



def GetUnusedLocalhostPort():
    sock = socket.socket()
    # This tells the OS to give us any free port in the range [1024 - 65535]
    sock.bind(( '', 0 ))
    port = sock.getsockname()[1]
    sock.close()
    return port

class Server():
    def __init__(self):
        # FIXME: determine dynamically
        self.port = GetUnusedLocalhostPort()

        self.http_server = HTTPServer(('', self.port), HTTPRequestHandler)
        self.http_thread = Thread(target=self.run_http_server)

        self.editor_service_path = GetEditorServicePath()
        self.editor_service_thread = Thread(target=self.run_editor_service)

    def run_editor_service(self):
        self.editor_service = subprocess.Popen([self.editor_service_path,
            "editor", "TOK", "--port", str(self.port)])

    def run_http_server(self):
        try:
            self.http_server.serve_forever()
        except:
            pass
        finally:
            self.http_server.server_close()

    def start(self):
        self.http_thread.start()
        self.editor_service_thread.start()

    def stop(self):
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


