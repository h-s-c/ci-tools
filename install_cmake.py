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
import hashlib
import ssl

CMAKE_BASE_URL = "http://cmake.org/files/v3.28/"
CMAKE_VERSION = "3.28.3"
CMAKE_FILENAME_LINUX = "cmake-"+CMAKE_VERSION+"-linux-x86_64"
CMAKE_FILENAME_LINUX_ARM64 = "cmake-"+CMAKE_VERSION+"-linux-aarch64"
CMAKE_FILENAME_WINDOWS = "cmake-"+CMAKE_VERSION+"-windows-x86_64"
CMAKE_FILENAME_MACOSX = "cmake-"+CMAKE_VERSION+"-macos-universal"
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

    if sys.version_info[0] >= 3:
        from urllib.request import urlretrieve
    else:
        from urllib import urlretrieve
    urlretrieve(url, filename)

def extract(filename):
    print("Extracting "+os.path.basename(filename))
    if filename.endswith('.zip'):
        opener, mode = zipfile.ZipFile, 'r'
    elif filename.endswith('.tar.gz') or filename.endswith('.tgz'):
        opener, mode = tarfile.open, 'r:gz'
    elif filename.endswith('.tar.bz2') or filename.endswith('.tbz'):
        opener, mode = tarfile.open, 'r:bz2'
    else: 
        raise Exception("Could not extract CMake.")
    
    file = opener(filename, mode)
    try: file.extractall()
    finally: file.close()

if __name__ == "__main__":
    CMAKE_FILENAME = CMAKE_FILENAME_LINUX  
    CMAKE_SUFFIX = CMAKE_SUFFIX_UNIX

    if platform.system() == "Linux":
        if platform.machine()[0] == "aarch64":
            CMAKE_FILENAME = CMAKE_FILENAME_LINUX_ARM64   
    elif platform.system() == "Windows":
        CMAKE_FILENAME = CMAKE_FILENAME_WINDOWS
        CMAKE_SUFFIX = CMAKE_SUFFIX_WINDOWS
    elif platform.system() == "Darwin":
        CMAKE_FILENAME = CMAKE_FILENAME_MACOSX

    os.chdir(os.path.join(os.getcwd(), "ci-tools"))
    if not os.path.exists(os.path.join(os.getcwd(), "cache")):
        os.mkdir(os.path.join(os.getcwd(), "cache"))

    while not os.path.isfile(os.path.join(os.getcwd(), "cache", "cmake-"+CMAKE_VERSION+"-SHA-256.txt")):
        download(CMAKE_BASE_URL+"cmake-"+CMAKE_VERSION+"-SHA-256.txt", os.path.join(os.getcwd(), "cache", "cmake-"+CMAKE_VERSION+"-SHA-256.txt"))
    
    done = False
    while not done:
        if os.path.isfile(os.path.join(os.getcwd(), "cache",CMAKE_FILENAME+CMAKE_SUFFIX)):
            print("Hashing "+CMAKE_FILENAME+CMAKE_SUFFIX)
            hasher = hashlib.sha256()
            with open(os.path.join(os.getcwd(), "cache", CMAKE_FILENAME+CMAKE_SUFFIX), 'rb') as file:
                hasher.update(file.read())
            with open(os.path.join(os.getcwd(), "cache", "cmake-"+CMAKE_VERSION+"-SHA-256.txt")) as search:
                for line in search:
                    if hasher.hexdigest() in line:
                        done = True
            if not done:
                os.remove(os.path.join(os.getcwd(), "cache",CMAKE_FILENAME+CMAKE_SUFFIX))
        else:
            download(CMAKE_BASE_URL+CMAKE_FILENAME+CMAKE_SUFFIX, os.path.join(os.getcwd(), "cache", CMAKE_FILENAME+CMAKE_SUFFIX))

    if os.path.exists(os.path.join(os.getcwd(), CMAKE_FILENAME)):
        shutil.rmtree(os.path.join(os.getcwd(), CMAKE_FILENAME))

    extract(os.path.join(os.getcwd(), "cache", CMAKE_FILENAME+CMAKE_SUFFIX))

    if os.path.exists(os.path.join(os.getcwd(), "cmake")):
        shutil.rmtree(os.path.join(os.getcwd(), "cmake"))

    os.rename(os.path.join(os.getcwd(), CMAKE_FILENAME), os.path.join(os.getcwd(), "cmake"))