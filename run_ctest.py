#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os

def shell_source(script):
    """Sometime you want to emulate the action of "source" in bash,
    settings some environment variables. Here is a way to do it."""
    import subprocess, os
    pipe = subprocess.Popen(". %s; env" % script, stdout=subprocess.PIPE, shell=True)
    output = pipe.communicate()[0]
    env = dict((line.split("=", 1) for line in output.splitlines()))
    os.environ.update(env)

if __name__ == "__main__":
    if platform.system() == "Linux" or platform.system() == "Darwin":
        CMAKE_DEST = os.environ.get("HOME")+"/ci-tools/cmake"
        ICC_DEST = os.environ.get("HOME")+"/ci-tools/icc"
        os.environ("PATH") = CMAKE_DEST+":"+os.environ.get("PATH")
        if os.path.exists(ICC_DEST):
            os.environ("LD_LIBRARY_PATH") = ICC_DEST+";"+os.environ.get("LD_LIBRARY_PATH")
            shell_source("source "+ICC_DEST+"/bin/compilervars.sh intel64")
    elif platform.system() == "Windows":
        CMAKE_DEST = os.environ.get("TMP")+"/ci-tools/cmake"
        os.environ("PATH") = CMAKE_DEST+";"+os.getenv("PATH")

    os.system("ctest -S ci-tools/run_ctest.cmake")