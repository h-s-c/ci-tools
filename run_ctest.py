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
    if platform.system() == "Linux":
        os.environ["PATH"] = os.environ.get("HOME")+"/ci-tools/cmake/bin"+":"+os.environ.get("PATH")
        ICC_DEST = os.environ.get("HOME")+"/ci-tools/icc"
        if os.path.exists(ICC_DEST):
            os.environ["LD_LIBRARY_PATH"] = ICC_DEST+"/ism/bin/intel64"+":"+ICC_DEST+"/lib/intel64_lin"
            shell_source("source "+ICC_DEST+"/bin/compilervars.sh intel64")
    elif platform.system() == "Windows":
        os.environ["PATH"] = os.environ.get("TMP")+"\\ci-tools\\cmake\\bin"+";"+os.environ.get("PATH")
    elif platform.system() == "Darwin":
        os.environ["PATH"] = os.environ.get("HOME")+"/ci-tools/cmake/CMake.app/Contents/bin"+":"+os.environ.get("PATH")

    if os.system("ctest -S ci-tools/run_ctest.cmake") != 0:
        raise Exception("CTest returned an error.")