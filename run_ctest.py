#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os
import subprocess

if __name__ == "__main__":
    # Figure out path of our own cmake install
    CITOOLS_PATH = os.path.join(os.getcwd(), "ci-tools")
    CMAKE_PATH = os.path.join(CITOOLS_PATH, "cmake")
    if platform.system() == "Linux":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Windows":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+";"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Darwin":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "CMake.app", "Contents", "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))

    subprocess.check_call("ctest -S ci-tools/run_ctest.cmake", shell=True)
