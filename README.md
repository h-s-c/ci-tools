# CI-Tools
[![license](https://img.shields.io/github/license/h-s-c/ci-tools.svg)](http://unlicense.org/)

##
Continous integration toolkit for use with CMake written in Python.

## Install
### Add ci-tools to your project.
```bash
git submodule add https://github.com/h-s-c/ci-tools
```

## CI pipeline usage
### Install local CMake (Only really useful if you don't control your CI environment).
```bash
ci-tools/install_cmake.py
```

### Run tests defined in your CMakeLists.txt. Optionally detects and uses static and dynamic analyzers like Valgrind, AddressSanitizer, MemorySanitizer, ThreadSanitizer, UndefinedBehaviorSanitizer if available in your CI environment. Uploads your results to a CDash dashboard if you provide a CTestConfig.cmake in your project folder.
```bash
export CC=gcc
ci-tools/run_ctest.py
```

### On windows its something like this:
```bash
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
set CC=cl
ci-tools/run_ctest.py
```


### Packages your app if you provide a CPackConfig.cmake in your project folder.
```bash
ci-tools/run_cpack.py
```