import os
import sys
# Add the location of of the .so to the python path
build_root = os.path.join(os.path.dirname(os.path.dirname(__file__)),
        '.build')
sys.path.append(build_root)

import swiftvim
print("build_root", build_root)
stats = swiftvim.load()
result = swiftvim.load()
print("Loaded spmvim", result)
