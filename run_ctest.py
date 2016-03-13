#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os
import subprocess

if __name__ == "__main__":
    CITOOLS_PATH = os.path.join(os.getcwd(), "ci-tools")
    CMAKE_PATH = os.path.join(CITOOLS_PATH, "cmake")
    ICC_PATH = os.path.join(CITOOLS_PATH, "icc")

    if platform.system() == "Linux":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
        if os.path.exists(ICC_PATH):
            os.environ["LD_LIBRARY_PATH"] = os.path.join(ICC_PATH, "ism", "bin", "intel64")+":"+os.path.join(ICC_PATH, "lib", "intel64_lin")
    elif platform.system() == "Windows":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+";"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Darwin":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "CMake.app", "Contents", "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))

    if subprocess.call("ctest -VV -S ci-tools/run_ctest.cmake", shell=True) != 0:
        raise Exception("ctest returned an error.")
