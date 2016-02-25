#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import platform
import urllib
import zipfile
import tarfile
import os
import shutil
import ssl

CMAKE_BASE_URL = "https://cmake.org/files/v3.5/"
CMAKE_FILENAME_LINUX_32 = "cmake-3.5.0-rc3-Linux-i386"
CMAKE_FILENAME_LINUX_64 = "cmake-3.5.0-rc3-Linux-x86_64"
CMAKE_FILENAME_WINDOWS = "cmake-3.5.0-rc3-win32-x86"
CMAKE_FILENAME_MACOSX = "cmake-3.5.0-rc3-Darwin-x86_64"
CMAKE_SUFFIX_UNIX = ".tar.gz"
CMAKE_SUFFIX_WINDOWS = ".zip"

def download(url):
    print "Downloading "+url
    filename = url.split("/")[-1]
    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context
    urllib.urlretrieve(url, filename)

def extract(filename):
    print "Extracting "+filename
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


def copy(source, dest):
    print "Copying to "+dest
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(source, dest)

if __name__ == "__main__":
    if platform.system() == "Linux":
        if platform.architecture()[0] == "32bit":
            CMAKE_FILENAME = CMAKE_FILENAME_LINUX_32
        elif platform.architecture()[0] == "64bit":
            CMAKE_FILENAME = CMAKE_FILENAME_LINUX_64   
        CMAKE_SUFFIX = CMAKE_SUFFIX_UNIX
        CMAKE_DEST = os.environ.get("HOME")+"/ci-tools/cmake"
    elif platform.system() == "Windows":
        CMAKE_FILENAME = CMAKE_FILENAME_WINDOWS
        CMAKE_SUFFIX = CMAKE_SUFFIX_WINDOWS
        CMAKE_DEST = os.environ.get("TMP")+"/ci-tools/cmake"
    elif platform.system() == "Darwin":
        CMAKE_FILENAME = CMAKE_FILENAME_MACOSX
        CMAKE_SUFFIX = CMAKE_SUFFIX_UNIX
        CMAKE_DEST = os.environ.get("HOME")+"/ci-tools/cmake"

    if not os.path.exists(CMAKE_DEST):
        os.makedirs(CMAKE_DEST)
    os.chdir(CMAKE_DEST)

    download(CMAKE_BASE_URL+CMAKE_FILENAME+CMAKE_SUFFIX)
    extract(CMAKE_FILENAME+CMAKE_SUFFIX)
    copy(CMAKE_FILENAME, CMAKE_DEST)