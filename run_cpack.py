#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os
import subprocess
import shutil

if __name__ == "__main__":
    CITOOLS_PATH = os.path.join(os.getcwd(), "ci-tools")
    CMAKE_PATH = os.path.join(CITOOLS_PATH, "cmake")

    if platform.system() == "Linux":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Windows":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "bin")+";"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))
    elif platform.system() == "Darwin":
        os.environ["PATH"] = os.path.join(CMAKE_PATH, "CMake.app", "Contents", "bin")+":"+os.environ.get("PATH", os.path.join(CMAKE_PATH, "bin"))

    if subprocess.call("cmake -DCMAKE_BUILD_TYPE=Release -G Ninja -Bbuild -H.", shell=True) != 0:
        raise Exception("CMake returned an error.")
    if subprocess.call("ninja -C build", shell=True) != 0:
        if subprocess.call("ninja-build -C build", shell=True) != 0:
            raise Exception("Ninja returned an error.")
    if subprocess.call("cpack", shell=True) != 0:
        raise Exception("CPack returned an error.")

    if os.path.exists(os.path.join(os.getcwd(), "_CPack_Packages")):
        shutil.rmtree(os.path.join(os.getcwd(), "_CPack_Packages"))
