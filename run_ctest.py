#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os
import subprocess
import sys

if platform.system() == "Windows":
    import distutils.msvc9compiler as msvc

if __name__ == "__main__":
    CITOOLS_PATH = os.path.join(os.getcwd(), "ci-tools")
    CMAKE_PATH = os.path.join(CITOOLS_PATH, "cmake")

    if platform.system() == "Linux":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Windows":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+";"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
        if len(sys.argv) > 1:
            msvc.find_vcvarsall = lambda _: sys.argv[1]
            envs = msvc.query_vcvarsall(sys.argv[2])
            for k,v in envs.items():
                k = k.upper()
                v = ":".join(subprocess.check_output(["cygpath","-u",p]).rstrip() for p in v.split(";"))
                v = v.replace("'\''",r"'\'\\\'\''")
                print "export %(k)s='\''%(v)s'\''" % locals()
    elif platform.system() == "Darwin":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "CMake.app", "Contents", "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))

    if subprocess.call("ctest -VV -S ci-tools/run_ctest.cmake", shell=True) != 0:
        raise Exception("CTest returned an error.")
