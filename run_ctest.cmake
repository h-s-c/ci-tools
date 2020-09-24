# 3.1: Required by CTEST_COVERAGE_EXTRA_FLAGS and CTEST_UPDATE_VERSION_ONLY
# 3.5: Required by COBERTURADIR
# 3.7: Required by GREATER_EQUAL
# 3.8: Required by fixed CTEST_MEMORYCHECK_SANITIZER_OPTIONS
# 3.18: Required by STOP_ON_FAILURE
cmake_minimum_required(VERSION 3.18)

if(NOT DEFINED ENV{CI})
    message(FATAL_ERROR "Not a CI server.")
endif()

if(DEFINED ENV{CC})
    find_program(CC_FOUND NAMES $ENV{CC})
    if(NOT CC_FOUND)
        message( FATAL_ERROR "Compiler $ENV{CC} not found.")
    endif()
endif()

# Compiler
if(UNIX)
    if(DEFINED ENV{CC})
        get_filename_component(CC $ENV{CC} NAME)
        if(CC STREQUAL "icc")
            set(CC_NAME "icc")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
            exec_program($ENV{CC} ARGS -dumpmachine OUTPUT_VARIABLE CC_ARCH)
            set(CC_PLATFORM "${CC_ARCH}")
        elseif(CC STREQUAL "tcc")
            set(CC_NAME "tcc")
            exec_program($ENV{CC} ARGS -v OUTPUT_VARIABLE CC_VERSION_VERBOSE)
            string(REGEX REPLACE ".*tcc version ([0-9]+\\.[0-9]+).*" "\\1" CC_VERSION ${CC_VERSION_VERBOSE})
            set(CC_ARCH "x86_64")
            set(CC_PLATFORM "linux")
        elseif(CC STREQUAL "emcc")
            set(CC_NAME "emscripten")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
            set(CC_ARCH "wasm")  
            set(CC_PLATFORM "web")
        else()
            string(FIND "${CC}" "gcc" CC_GCC)
            if(CC_GCC GREATER_EQUAL 0)
                string(FIND "${CC}" "mingw" CC_MINGW)
                if(CC_MINGW GREATER_EQUAL 0)
                    #Warmup wine or test timings are going to be wrong
                    exec_program(wine ARGS version OUTPUT_VARIABLE WINE_VERSION)
                    #Start persistent wineserver
                    exec_program(wineserver ARGS --persistent)
                    set(CC_NAME "mingw")
                else()
                    set(CC_NAME "gcc")
                endif()
                exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
                if((CC_VERSION VERSION_GREATER 5) OR (CC_VERSION VERSION_EQUAL 5))
                    string(SUBSTRING "${CC_VERSION}" 0 1 CC_VERSION)
                else()
                    string(SUBSTRING "${CC_VERSION}" 0 3 CC_VERSION)
                endif()
                exec_program($ENV{CC} ARGS -dumpmachine OUTPUT_VARIABLE CC_ARCH)
                set(CC_PLATFORM "${CC_ARCH}")
            endif()
            string(FIND "${CC}" "clang" CC_CLANG)
            if(CC_CLANG GREATER_EQUAL 0)
                if(APPLE)
                    set(CC_NAME "xcode")
                    exec_program(xcodebuild ARGS -version OUTPUT_VARIABLE CC_VERSION_VERBOSE)
                    string(REGEX REPLACE ".*Xcode ([0-99]+\\.[0-99]+).*" "\\1" CC_VERSION ${CC_VERSION_VERBOSE})
                else()
                    set(CC_NAME "clang")
                    exec_program($ENV{CC} ARGS --version OUTPUT_VARIABLE CC_VERSION_VERBOSE)
                    string(REGEX REPLACE ".*clang version ([0-99]+\\.[0-99]+).*" "\\1" CC_VERSION ${CC_VERSION_VERBOSE})
                    if(CC_VERSION VERSION_GREATER 10.0 OR CC_VERSION VERSION_EQUAL 10.0)
                        string(SUBSTRING "${CC_VERSION}" 0 2 CC_VERSION)
                    elseif(CC_VERSION VERSION_GREATER 7.0 OR CC_VERSION VERSION_EQUAL 7.0)
                        string(SUBSTRING "${CC_VERSION}" 0 1 CC_VERSION)
                    endif()
                endif()
                exec_program($ENV{CC} ARGS -dumpmachine OUTPUT_VARIABLE CC_ARCH)
                set(CC_PLATFORM "${CC_ARCH}")
            endif()
        endif()
    else()
        set(CC_NAME "gcc")
        exec_program(${CC_NAME} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
        string(SUBSTRING "${CC_VERSION}" 0 3 CC_VERSION)
        exec_program($ENV{CC_NAME} ARGS -dumpmachine OUTPUT_VARIABLE CC_ARCH)
        set(CC_PLATFORM "${CC_ARCH}")
    endif()
    string(FIND "${CC_ARCH}" "x86_64" CC_ARCH_X86_64)
    string(FIND "${CC_ARCH}" "amd64" CC_ARCH_AMD64)
    string(FIND "${CC_ARCH}" "i786" CC_ARCH_I786)
    string(FIND "${CC_ARCH}" "i686" CC_ARCH_I686)
    string(FIND "${CC_ARCH}" "i586" CC_ARCH_I586)
    string(FIND "${CC_ARCH}" "i486" CC_ARCH_I486)
    string(FIND "${CC_ARCH}" "i386" CC_ARCH_I386)
    string(FIND "${CC_ARCH}" "aarch64" CC_ARCH_AARCH64)
    string(FIND "${CC_ARCH}" "arm" CC_ARCH_ARM)
    if(CC_ARCH_X86_64 GREATER_EQUAL 0 OR CC_ARCH_AMD64 GREATER_EQUAL 0)
        set(CC_ARCH "x86_64")
    elseif(CC_ARCH_I786 GREATER_EQUAL 0 OR CC_ARCH_I686 GREATER_EQUAL 0 OR CC_ARCH_I586 GREATER_EQUAL 0 OR CC_ARCH_I486 GREATER_EQUAL 0 OR CC_ARCH_I386 GREATER_EQUAL 0)
        set(CC_ARCH "x86")
    elseif(CC_ARCH_AARCH64 GREATER_EQUAL 0)
        set(CC_ARCH "arm64")
    elseif(CC_ARCH_ARM GREATER_EQUAL 0)
        set(CC_ARCH "arm")
    endif()
    string(FIND "${CC_PLATFORM}" "android" CC_PLATFORM_ANDROID)
    if(CC_PLATFORM_ANDROID GREATER_EQUAL 0)
        set(CC_PLATFORM "android")
    endif()
    string(FIND "${CC_PLATFORM}" "Win64" CC_PLATFORM_WIN64)
    string(FIND "${CC_PLATFORM}" "Win32" CC_PLATFORM_WIN32)
    string(FIND "${CC_PLATFORM}" "mingw" CC_PLATFORM_MINGW)
    if(CC_PLATFORM_WIN64 GREATER_EQUAL 0 OR CC_PLATFORM_WIN32 GREATER_EQUAL 0 OR CC_PLATFORM_MINGW GREATER_EQUAL 0)
        set(CC_PLATFORM "windows")
    endif()
    string(FIND "${CC_PLATFORM}" "linux" CC_PLATFORM_LINUX)
    if(CC_PLATFORM_LINUX GREATER_EQUAL 0)
        set(CC_PLATFORM "linux")
    endif()
    string(FIND "${CC_PLATFORM}" "darwin" CC_PLATFORM_DARWIN)
    if(CC_PLATFORM_DARWIN GREATER_EQUAL 0)
        set(CC_PLATFORM "macos")
    endif()
else()
    set(CC_NAME "msvc")
    set(CC_PLATFORM "windows")
    exec_program(cl.exe OUTPUT_VARIABLE CC_VERSION_VERBOSE)
    message( WARNING "DEBUG: ${CC_VERSION_VERBOSE}")
    string(FIND "${CC_VERSION_VERBOSE}" "19.2" CC_VERSION_2019)
    if(CC_VERSION_2019 GREATER_EQUAL 0)
        set(CC_VERSION "2019")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "19.1" CC_VERSION_2017)
    if(CC_VERSION_2017 GREATER_EQUAL 0)
        set(CC_VERSION "2017")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "19.0" CC_VERSION_2015)
    if(CC_VERSION_2015 GREATER_EQUAL 0)
        set(CC_VERSION "2015")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "18.0" CC_VERSION_2013)
    if(CC_VERSION_2013 GREATER_EQUAL 0)
        set(CC_VERSION "2013")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "x86" CC_ARCH_X86)
    if(CC_ARCH_X86 GREATER_EQUAL 0)
        set(CC_ARCH "x86")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "x64" CC_ARCH_X86_64)
    if(CC_ARCH_X86_64 GREATER_EQUAL 0)
        set(CC_ARCH "x86_64")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "amd64" CC_ARCH_AMD64)
    if(CC_ARCH_AMD64 GREATER_EQUAL 0)
        set(CC_ARCH "x86_64")
    endif()
    string(FIND "${CC_VERSION_VERBOSE}" "ARM" CC_ARCH_ARM)
    if(CC_ARCH_ARM GREATER_EQUAL 0)
        set(CC_ARCH "arm")
    endif()
endif()
string(LENGTH "${CC_PLATFORM}" CC_PLATFORM_LENGTH)
if(CC_PLATFORM_LENGTH GREATER 7 OR CC_PLATFORM_LENGTH LESS 3)
    message( FATAL_ERROR "Platform ${CC_PLATFORM} not supported.")
endif()
string(LENGTH "${CC_ARCH}" CC_ARCH_LENGTH)
if(CC_ARCH_LENGTH GREATER 6 OR CC_ARCH_LENGTH LESS 3)
    message( FATAL_ERROR "Architecture ${CC_ARCH} not supported.")
endif()
set(CI_BUILD_NAME "${CC_NAME}-${CC_VERSION}-${CC_PLATFORM}-${CC_ARCH}")

# CI service
if(DEFINED ENV{APPVEYOR})
    set(CTEST_SITE "Appveyor CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{APPVEYOR_BUILD_FOLDER}")
elseif(DEFINED ENV{CIRCLECI})
    set(CTEST_SITE "Circle CI")
elseif(DEFINED ENV{DRONE})
    set(CTEST_SITE "Drone CI")
elseif(DEFINED ENV{GITHUB_WORKSPACE})
    set(CTEST_SITE "Github CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{GITHUB_WORKSPACE}")
elseif(DEFINED ENV{GITLAB_CI})
    set(CTEST_SITE "GitLab CI")
elseif(DEFINED ENV{MAGNUM})
    set(CTEST_SITE "Magnum CI")
elseif(DEFINED ENV{SCRUTINIZER})
    set(CTEST_SITE "Scrutinizer CI")
elseif(DEFINED ENV{SEMAPHORE})
    set(CTEST_SITE "Semaphore CI")
elseif(DEFINED ENV{SHIPPABLE})
    set(CTEST_SITE "Shippable CI")
elseif(DEFINED ENV{TRAVIS})
    set(CTEST_SITE "Travis CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{TRAVIS_BUILD_DIR}")
elseif(DEFINED ENV{WERCKER_ROOT})
    set(CTEST_SITE "Wercker CI")
elseif(DEFINED ENV{GIT_COMMIT} AND DEFINED ENV{BUILD_NUMBER} AND DEFINED ENV{WORKSPACE})
    set(CTEST_SITE "Jenkins CI")
elseif(DEFINED ENV{CI_NAME})
    if($ENV{CI_NAME} STREQUAL "codeship")
        set(CTEST_SITE "Codeship CI")
    endif()
else()
    set(CTEST_SITE "Custom CI")
endif()

string(RANDOM CI_BUILD_UUID_RANDOM)
string(UUID CI_BUILD_UUID NAMESPACE cd1ae0ac-17b9-4018-85da-921f0d3ae8d8 NAME ${CI_BUILD_UUID_RANDOM} TYPE SHA1)

if(UNIX)
    if(NOT DEFINED ${CTEST_SOURCE_DIRECTORY})
        set(CTEST_SOURCE_DIRECTORY "$ENV{PWD}")
    endif()
    set(CTEST_BINARY_DIRECTORY "$ENV{HOME}/build/${CI_BUILD_UUID}")
else()
    set(CTEST_BINARY_DIRECTORY "$ENV{TMP}\\build\\${CI_BUILD_UUID}")
endif()

set(CTEST_UPDATE_VERSION_ONLY TRUE)
set(CTEST_OUTPUT_ON_FAILURE TRUE)
set(CTEST_GIT_COMMAND "git")

set(CTEST_CONFIGURATION_TYPE "Debug")

# Default
set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-default")
ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
ctest_start(Continuous)
ctest_update()
ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
    ctest_configure(OPTIONS "-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
else()
    ctest_configure()
endif()
ctest_build()
ctest_test(STOP_ON_FAILURE)
ctest_submit(PARTS Start Update Configure Build Test Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)

# Coverage
if(CC_NAME STREQUAL "gcc")
    find_program(CTEST_COVERAGE_COMMAND NAMES gcov-${CC_VERSION})
    if(NOT CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
    endif()
elseif(CC_NAME STREQUAL "mingw")
    find_program(CTEST_COVERAGE_COMMAND NAMES x86_64-w64-mingw32-gcov i686-w64-mingw32-gcov x86_64-w64-mingw32.static-gcov i686-w64-mingw32.static-gcov)
elseif(CC_NAME STREQUAL "clang")
    find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov-${CC_VERSION})
    if(NOT CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov)
    endif()
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} gcov")
    endif()
    if(CC_VERSION VERSION_EQUAL 3.6)
        set(CTEST_COVERAGE_COMMAND "")
        set(CTEST_COVERAGE_EXTRA_FLAGS "")
    endif()
elseif(CC_NAME STREQUAL "xcode")
    find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov PATHS /Library/Developer/CommandLineTools/usr/bin/)
    if(CC_VERSION VERSION_GREATER 7.3 OR CC_VERSION VERSION_EQUAL 7.3)
        set(CTEST_COVERAGE_COMMAND "")
        set(CTEST_COVERAGE_EXTRA_FLAGS "")
    elseif(CC_VERSION VERSION_GREATER 6.3 OR CC_VERSION VERSION_EQUAL 6.3)
        set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} gcov")
    endif()
elseif(CC_NAME STREQUAL "icc")
    set(CTEST_COVERAGE_COMMAND codecov)
    set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} -txtlcov")
elseif(CC_NAME STREQUAL "msvc")
    find_program(CTEST_COVERAGE_COMMAND NAMES OpenCppCoverage)
    if(NOT CTEST_COVERAGE_COMMAND)
        message(FATAL_ERROR "OpenCppCoverage not found!")
    endif()
endif()
if(CTEST_COVERAGE_COMMAND)
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-cov")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    if(CC_NAME STREQUAL "gcc" OR CC_NAME STREQUAL "clang" OR CC_NAME STREQUAL "xcode")
        set(CC_COVERAGE_FLAGS "--coverage")
    elseif(CC_NAME STREQUAL "icc")
        set(CC_COVERAGE_FLAGS "-prof-gen:srcpos -prof-dir=${CTEST_BINARY_DIRECTORY}")
    endif()
if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
    ctest_configure(OPTIONS "-DCI_FLAGS=${CC_COVERAGE_FLAGS};-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
else()
    ctest_configure(OPTIONS "-DCI_FLAGS=${CC_COVERAGE_FLAGS}")
endif()
    ctest_build()
    ctest_test(STOP_ON_FAILURE)
    if(CC_NAME STREQUAL "msvc")
        exec_program(ctest ${CTEST_BINARY_DIRECTORY} ARGS -N OUTPUT_VARIABLE OCC_TESTS)
        set(OCC_ABORT 0)
        set(OCC_LASTTEST "")
        while(OCC_ABORT GREATER -1)
            string(REGEX MATCH "#[0-9]+: [^\r\n\t\\\\]+" OCC_TEST ${OCC_TESTS})
            string(REGEX REPLACE ${OCC_TEST} "" OCC_TESTS ${OCC_TESTS})
            string(REGEX MATCH "#[0-9]+: " OCC_TEMP ${OCC_TEST})
            string(REGEX REPLACE ${OCC_TEMP} "" OCC_TEST ${OCC_TEST})
            exec_program(${CTEST_COVERAGE_COMMAND} ${CTEST_BINARY_DIRECTORY} ARGS --sources ${CTEST_SOURCE_DIRECTORY}\\source --modules *${CI_BUILD_UUID}* --cover_children --export_type=cobertura -- ${OCC_TEST}.exe)
            file(READ ${CTEST_BINARY_DIRECTORY}/${OCC_TEST}Coverage.xml OCC_TESTXML)
            string(REGEX REPLACE "package name=[^ ]+\"" "package name=\"merged\"" OCC_TESTXML ${OCC_TESTXML})
            string(REGEX REPLACE "filename=[^ ]+\\source." "filename=\"source/" OCC_TESTXML ${OCC_TESTXML})
            string(REGEX REPLACE "<source>[^ ]+</source>" "<source>source</source>" OCC_TESTXML ${OCC_TESTXML})
            file(WRITE ${CTEST_BINARY_DIRECTORY}/${OCC_TEST}Coverage.xml ${OCC_TESTXML})
            string(FIND ${OCC_TESTS} "#" OCC_ABORT)
        endwhile()
        exec_program(python ${CTEST_SOURCE_DIRECTORY} ARGS ci-tools/merge_cobertura.py -p "${CTEST_BINARY_DIRECTORY}" -o "${CTEST_BINARY_DIRECTORY}\\coverage.xml")
        set(ENV{COBERTURADIR} "${CTEST_BINARY_DIRECTORY}")
    endif()
    ctest_coverage()
    if(UNIX)
        exec_program(curl $ENV{HOME} ARGS -s https://codecov.io/bash OUTPUT_VARIABLE CODECOV)
        file(WRITE $ENV{HOME}/codecov.io "${CODECOV}")
        exec_program(chmod $ENV{HOME} ARGS +x codecov.io)
        exec_program($ENV{HOME}/codecov.io ${CTEST_SOURCE_DIRECTORY} ARGS -X gcov -s ${CTEST_BINARY_DIRECTORY})
    endif()
    ctest_submit(PARTS Start Update Configure Build Test Coverage Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
endif()

# Static analysis
if(CC_NAME STREQUAL "msvc" OR CC_NAME STREQUAL "clang")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-analyzer")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    if(CC_NAME STREQUAL "msvc")
        set(CC_ANALYSE_FLAGS "/analyze /wd28251 /wd28301")
    elseif(CC_NAME STREQUAL "clang")
        set(CC_ANALYSE_FLAGS "--analyze -Wno-unused-command-line-argument")
    endif()
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        ctest_configure(OPTIONS "-DKD_BUILD_TESTS=0;-DCI_FLAGS=${CC_ANALYSE_FLAGS};-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
    else()
        ctest_configure(OPTIONS "-DKD_BUILD_TESTS=0;-DCI_FLAGS=${CC_ANALYSE_FLAGS}")
    endif()
    ctest_build()
    ctest_submit(PARTS Start Update Configure Build Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
endif()

# Dynamic analysis (Valgrind)
find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
if(CTEST_MEMORYCHECK_COMMAND)
    set(CTEST_MEMORYCHECK_TYPE "Valgrind")
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --track-origins=yes --leak-check=full --show-reachable=yes --gen-suppressions=all")
    if(EXISTS "${CTEST_SOURCE_DIRECTORY}/valgrind.supp")
        set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "${CTEST_MEMORYCHECK_COMMAND_OPTIONS} --suppressions=${CTEST_SOURCE_DIRECTORY}/valgrind.supp")
    endif()
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-valgrind")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        ctest_configure(OPTIONS "-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
    else()
        ctest_configure()
    endif()
    ctest_build()
    ctest_test(STOP_ON_FAILURE)
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
    set(CTEST_MEMORYCHECK_COMMAND "")
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "")
endif()

function(has_sanitizer has_sanitizer_arg has_sanitizer_retval)
    set(retval 0)
    if(UNIX AND NOT APPLE)
        set(CI_ALPINE 0)
        execute_process(COMMAND cat /etc/os-release COMMAND grep -c Alpine OUTPUT_VARIABLE CI_ALPINE)
        if(CI_ALPINE EQUAL 0)
            execute_process(COMMAND ldconfig -p COMMAND grep -c ${has_sanitizer_arg} OUTPUT_VARIABLE retval )
        endif()
    endif()
    set(${has_sanitizer_retval} ${retval} PARENT_SCOPE)
endfunction()

has_sanitizer("asan" CC_ASAN)
has_sanitizer("msan" CC_MSAN)
has_sanitizer("tsan" CC_TSAN)
has_sanitizer("ubsan" CC_UBSAN)

# Dynamic analysis (ASan)
# ASan was introduced in GCC 4.8 / Clang 3.1
# ASan on Android only works with Clang
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 4.8 OR CC_VERSION VERSION_EQUAL 4.8)
        if(CC_ASAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "AddressSanitizer")
            set(CC_ASAN_FLAGS "-fuse-ld=gold")
        endif()
    endif()
    if(CC_PLATFORM STREQUAL "android")
        set(CTEST_MEMORYCHECK_TYPE "")
    endif()
elseif(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.1 OR CC_VERSION VERSION_EQUAL 3.1)
        if(CC_ASAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "AddressSanitizer")
            if(CC_VERSION VERSION_LESS 3.8)
                set(CC_ASAN_FLAGS "-fuse-ld=gold")
            endif()
        endif()
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "AddressSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-asan")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    set(CC_ASAN_FLAGS "${CC_ASAN_FLAGS} -fsanitize=address")
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_ASAN_FLAGS};-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
    else()
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_ASAN_FLAGS}")
    endif()
    ctest_build()
    ctest_test(STOP_ON_FAILURE)
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
endif()

# Dynamic analysis (MSan)
# MSan was introduced in Clang 3.3
if(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.3 OR CC_VERSION VERSION_EQUAL 3.3)
        if(CC_MSAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "MemorySanitizer")
        endif()
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "MemorySanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-msan")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    set(CC_MSAN_FLAGS "-fsanitize=memory -fsanitize-memory-track-origins")
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_MSAN_FLAGS};-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
    else()
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_MSAN_FLAGS}")
    endif()
    ctest_build()
    ctest_test(STOP_ON_FAILURE)
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
endif()

# Dynamic analysis(TSan)
# TSan was introduced in GCC 4.8 / Clang 3.2
# TSan works with non-pie builds starting GCC 5 / Clang 3.7
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 5 OR CC_VERSION VERSION_EQUAL 5)
        if(CC_TSAN GREATER 0)
            execute_process(COMMAND cat /etc/os-release COMMAND grep -c Ubuntu OUTPUT_VARIABLE CI_UBUNTU )
            execute_process(COMMAND cat /etc/os-release COMMAND grep -c Debian OUTPUT_VARIABLE CI_DEBIAN )
            if(CI_UBUNTU EQUAL 0 AND CI_DEBIAN EQUAL 0)
                set(CTEST_MEMORYCHECK_TYPE "ThreadSanitizer")
            endif()
        endif()
    endif()
elseif(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        if(CC_TSAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "ThreadSanitizer")
        endif()
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "ThreadSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-tsan")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    set(CC_TSAN_FLAGS "-fsanitize=thread")
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_TSAN_FLAGS};-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
    else()
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_TSAN_FLAGS}")
    endif()
    ctest_build()
    ctest_test(STOP_ON_FAILURE)
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
endif()

# Dynamic analysis (UBSan)
# UBan was introduced in GCC 4.9 / Clang 3.3
# UBSan respects log_path starting Clang 3.7
if(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        if(CC_UBSAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "UndefinedBehaviorSanitizer")
        endif()
    endif()
endif()
if(CC_NAME STREQUAL "emscripten")
    if(CC_VERSION VERSION_GREATER 1.38.34 OR CC_VERSION VERSION_EQUAL 1.38.34)
        set(CTEST_MEMORYCHECK_TYPE "UndefinedBehaviorSanitizer")
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "UndefinedBehaviorSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1 print_stacktrace=1")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-ubsan")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    set(CC_UBSAN_FLAGS "-fsanitize=undefined")
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_UBSAN_FLAGS};-DCMAKE_TOOLCHAIN_FILE=$ENV{CMAKE_TOOLCHAIN_FILE}")
    else()
        ctest_configure(OPTIONS "-DCI_FLAGS=${CC_UBSAN_FLAGS}")
    endif()
    ctest_build()
    ctest_test(STOP_ON_FAILURE)
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit RETRY_COUNT 100 RETRY_DELAY 10)
endif()