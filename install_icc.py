#!/usr/bin/python
# -*- coding: utf-8 -*-

import platform
import os

if __name__ == "__main__":
    if platform.system() == "Linux" or platform.system() == "Darwin":
        ICC_DEST = os.getenv("TMPDIR")+"/icc"
    elif platform.system() == "Windows":
        ICC_DEST = os.getenv("TMP")+"/icc"

    os.system("sudo /bin/sh `pwd`/ci/install_icc.sh --dest "+ICC_DEST)