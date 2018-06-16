import os
import sys
# Add the location of of the .so to the python path
src_root = os.path.dirname(os.path.dirname(__file__))
build_root = os.path.join(src_root, '.build')
sys.path.append(build_root)

runtime_dir = os.path.join(src_root, 'Tests',
    'VimInterfaceTests','MockVimRuntime')
sys.path.append(runtime_dir)

import vim
import spmvim
print("build_root", build_root)
result = spmvim.load()
print("Loaded spmvim", result)
from time import sleep
sleep(100000)
