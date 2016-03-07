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
        CTEST = os.path.join(CMAKE_PATH, "bin", "ctest")
        if os.path.exists(ICC_PATH):
            os.environ["LD_LIBRARY_PATH"] = os.path.join(ICC_PATH, "ism", "bin", "intel64")+":"+os.path.join(ICC_PATH, "lib", "intel64_lin")
    elif platform.system() == "Windows":
        CTEST = os.path.join(CMAKE_PATH, "bin", "ctest")
    elif platform.system() == "Darwin":
        CTEST = os.path.join(CMAKE_PATH, "CMake.app", "Contents", "bin", "ctest")

    if subprocess.call(CTEST+" -VV -S ci-tools/run_ctest.cmake", shell=True) != 0:
        raise Exception("ctest returned an error.")
