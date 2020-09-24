#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os
import subprocess
import shutil

if __name__ == "__main__":
    # Start persistent wineserver for faster MinGW tests
    if platform.system() == "Linux":
        if shutil.which("wineserver"):
            subprocess.call("wineserver -p", shell=True)

    # Figure out path of our own cmake install
    CITOOLS_PATH = os.path.join(os.getcwd(), "ci-tools")
    CMAKE_PATH = os.path.join(CITOOLS_PATH, "cmake")
    if platform.system() == "Linux":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Windows":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+";"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Darwin":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "CMake.app", "Contents", "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))

    subprocess.call("ctest -VV -S ci-tools/run_ctest.cmake", shell=True, check=True)
