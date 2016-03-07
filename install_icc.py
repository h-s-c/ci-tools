#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os

if __name__ == "__main__":
    CITOOLS_PATH = os.path.join(os.getcwd(), "ci-tools")
    ICC_PATH = os.path.join(CITOOLS_PATH, "icc")
    if platform.system() == "Linux" or platform.system() == "Darwin":
        os.system("sudo /bin/sh "+os.path.join(CITOOLS_PATH, "install_icc.sh")+" --dest "+ICC_PATH)
    elif platform.system() == "Windows":
        #TODO