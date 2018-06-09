
class MockRuntime():
    def __init__(self):
        self.data = []
        self.command = lambda value : None
        self.eval = lambda value : value


runtime = MockRuntime()

# Actual Vim APIS

def command(value):
    return runtime.command(value)

def eval(value):
    return runtime.eval(value)

# Test helpers

def eval_int(value):
    return int(value)

def eval_bool(value):
    return True

def py_exec(value):
    exec(value)

