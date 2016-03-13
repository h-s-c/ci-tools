#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function
import sys
import platform
import urllib
import zipfile
import tarfile
import os
import shutil
import ssl

CMAKE_BASE_URL = "https://cmake.org/files/v3.5/"
CMAKE_FILENAME_LINUX_32 = "cmake-3.5.0-Linux-i386"
CMAKE_FILENAME_LINUX_64 = "cmake-3.5.0-Linux-x86_64"
CMAKE_FILENAME_WINDOWS = "cmake-3.5.0-win32-x86"
CMAKE_FILENAME_MACOSX = "cmake-3.5.0-Darwin-x86_64"
CMAKE_SUFFIX_UNIX = ".tar.gz"
CMAKE_SUFFIX_WINDOWS = ".zip"

def download(url, filename):
    print("Downloading "+url)
    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context
    urllib.urlretrieve(url, filename)

def extract(filename):
    print("Extracting "+os.path.basename(filename))
    if filename.endswith('.zip'):
        opener, mode = zipfile.ZipFile, 'r'
    elif filename.endswith('.tar.gz') or filename.endswith('.tgz'):
        opener, mode = tarfile.open, 'r:gz'
    elif filename.endswith('.tar.bz2') or filename.endswith('.tbz'):
        opener, mode = tarfile.open, 'r:bz2'
    else: 
        raise ValueError, "Could not extract `%s` as no appropriate extractor is found" % filename
    
    file = opener(filename, mode)
    try: file.extractall()
    finally: file.close()

if __name__ == "__main__":
    if platform.system() == "Linux":
        if platform.architecture()[0] == "32bit":
            CMAKE_FILENAME = CMAKE_FILENAME_LINUX_32
        elif platform.architecture()[0] == "64bit":
            CMAKE_FILENAME = CMAKE_FILENAME_LINUX_64   
        CMAKE_SUFFIX = CMAKE_SUFFIX_UNIX
    elif platform.system() == "Windows":
        CMAKE_FILENAME = CMAKE_FILENAME_WINDOWS
        CMAKE_SUFFIX = CMAKE_SUFFIX_WINDOWS
    elif platform.system() == "Darwin":
        CMAKE_FILENAME = CMAKE_FILENAME_MACOSX
        CMAKE_SUFFIX = CMAKE_SUFFIX_UNIX

    os.chdir(os.path.join(os.getcwd(), "ci-tools"))

    download(CMAKE_BASE_URL+CMAKE_FILENAME+CMAKE_SUFFIX, os.path.join(os.getcwd(), CMAKE_FILENAME+CMAKE_SUFFIX))
    extract(os.path.join(os.getcwd(), CMAKE_FILENAME+CMAKE_SUFFIX))

    if os.path.exists(os.path.join(os.getcwd(), "cmake")):
        shutil.rmtree(os.path.join(os.getcwd(), "cmake"))

    os.rename(os.path.join(os.getcwd(), CMAKE_FILENAME), os.path.join(os.getcwd(), "cmake"))