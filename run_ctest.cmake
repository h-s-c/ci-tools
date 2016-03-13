if(UNIX)
    # # Required by CTEST_COVERAGE_EXTRA_FLAGS and CTEST_UPDATE_VERSION_ONLY
    cmake_minimum_required(VERSION 3.1)
else()
    # # Required by COBERTURADIR
    cmake_minimum_required(VERSION 3.5)
endif()

if(NOT DEFINED ENV{CI})
    message(FATAL_ERROR "Not a CI server.")
endif()

if(DEFINED ENV{CTEST_CMAKE_GENERATOR})
    set(CTEST_CMAKE_GENERATOR "$ENV{CTEST_CMAKE_GENERATOR}")
elseif(UNIX)
    set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
endif()

# Compiler
if(UNIX)
    if(DEFINED ENV{CC})
        find_program(CC_FOUND NAMES $ENV{CC})
        if(NOT CC_FOUND)
            message( FATAL_ERROR "Compiler $ENV{CC} not found." )
        endif()
        string(SUBSTRING "$ENV{CC}" 0 3 CC)
        if(CC STREQUAL "gcc")
            set(CC_NAME "gcc")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
            if((CC_VERSION VERSION_GREATER 5) OR (CC_VERSION VERSION_EQUAL 5))
                string(SUBSTRING "${CC_VERSION}" 0 1 CC_VERSION)
            else()
                string(SUBSTRING "${CC_VERSION}" 0 3 CC_VERSION)
            endif()
        elseif(CC STREQUAL "icc")
            set(CC_NAME "icc")
            exec_program($ENV{CC} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
        endif()
        string(SUBSTRING "$ENV{CC}" 0 5 CC)
        if(CC STREQUAL "clang")
            if(APPLE)
                set(CC_NAME "xcode")
                exec_program(xcodebuild ARGS -version OUTPUT_VARIABLE CC_VERSION)
                string(REGEX REPLACE ".*Xcode ([0-9]+\\.[0-9]+).*" "\\1" CC_VERSION ${CC_VERSION})
            else()
                set(CC_NAME "clang")
                exec_program($ENV{CC} ARGS --version OUTPUT_VARIABLE CC_VERSION)
                string(REGEX REPLACE ".*clang version ([0-9]+\\.[0-9]+).*" "\\1" CC_VERSION ${CC_VERSION})
            endif()
        endif()
    else()
        set(CC_NAME "gcc")
        exec_program(${CC_NAME} ARGS -dumpversion OUTPUT_VARIABLE CC_VERSION)
        string(SUBSTRING "${CC_VERSION}" 0 3 CC_VERSION)
    endif()
    exec_program(uname ARGS -m OUTPUT_VARIABLE CC_ARCH)
    if(${CC_ARCH} STREQUAL "x86_64" OR ${CC_ARCH} STREQUAL "amd64")
        set(CC_ARCH "x86_64")
    elseif(${CC_ARCH} STREQUAL "i386" OR ${CC_ARCH} STREQUAL "i486" OR ${CC_ARCH} STREQUAL "i586" OR ${CC_ARCH} STREQUAL "i686" OR ${CC_ARCH} STREQUAL "i786")
        set(CC_ARCH "x86")
    else()
        message(FATAL_ERROR "Platform ${CC_ARCH} not yet supported.")
    endif()
else()
    set(CC_NAME "msvc")
    string(SUBSTRING ${CTEST_CMAKE_GENERATOR} 14 2 CC_VERSION)
    if(${CTEST_CMAKE_GENERATOR} MATCHES ".*ARM")
        set(CC_ARCH "arm")
    elseif(${CTEST_CMAKE_GENERATOR} MATCHES ".*Win64")
        set(CC_ARCH "x86_64")
    else()
        set(CC_ARCH "x86")
    endif()
endif()

# CI service
if(DEFINED ENV{APPVEYOR})
    set(CTEST_SITE "Appveyor CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{APPVEYOR_BUILD_FOLDER}")
elseif(DEFINED ENV{CIRCLECI})
    set(CTEST_SITE "Circle CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{PWD}")
elseif(DEFINED ENV{DRONE})
    set(CTEST_SITE "Drone CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{DRONE_BUILD_DIR}")
elseif(DEFINED ENV{GITLAB_CI})
    set(CTEST_SITE "GitLab CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{CI_PROJECT_DIR}")
elseif(DEFINED ENV{MAGNUM})
    set(CTEST_SITE "Magnum CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{PWD}")
elseif(DEFINED ENV{SCRUTINIZER})
    set(CTEST_SITE "Scrutinizer CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{PWD}")
elseif(DEFINED ENV{SEMAPHORE})
    set(CTEST_SITE "Semaphore CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{SEMAPHORE_PROJECT_DIR}")
elseif(DEFINED ENV{SHIPPABLE})
    set(CTEST_SITE "Shippable CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{SHIPPABLE_REPO_DIR}")
elseif(DEFINED ENV{SNAP_CI})
    set(CTEST_SITE "Snap CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{SNAP_WORKING_DIR}")
elseif(DEFINED ENV{TRAVIS})
    set(CTEST_SITE "Travis CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{TRAVIS_BUILD_DIR}")
elseif(DEFINED ENV{WERCKER_ROOT})
    set(CTEST_SITE "Wercker CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{WERCKER_ROOT}")
elseif(DEFINED ENV{GIT_COMMIT} AND DEFINED ENV{BUILD_NUMBER} AND DEFINED ENV{WORKSPACE})
    set(CTEST_SITE "Jenkins CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{WORKSPACE}")
elseif(DEFINED ENV{CI_NAME})
    if($ENV{CI_NAME} STREQUAL "codeship")
        set(CTEST_SITE "Codeship CI")
        set(CTEST_SOURCE_DIRECTORY "$ENV{PWD}")
    endif()
else()
    set(CTEST_SITE "Custom CI")
    set(CTEST_SOURCE_DIRECTORY "$ENV{PWD}")
endif()
set(CI_BUILD_NAME "${CC_NAME}-${CC_VERSION}-${CC_ARCH}")

exec_program(python ${CTEST_SOURCE_DIRECTORY} ARGS ci-tools/create_uuid.py OUTPUT_VARIABLE CI_BUILD_UUID)

if(UNIX)
    set(CTEST_BINARY_DIRECTORY "$ENV{HOME}/build/${CI_BUILD_UUID}")
else()
    set(CTEST_BINARY_DIRECTORY "$ENV{TMP}\\build\\${CI_BUILD_UUID}")
endif()


set(CTEST_UPDATE_VERSION_ONLY TRUE)
set(CTEST_OUTPUT_ON_FAILURE TRUE)
set(CTEST_GIT_COMMAND "git")

set(CTEST_CONFIGURATION_TYPE "Release")
set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-release")
ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
ctest_start(Continuous)
ctest_update()
ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
ctest_configure()
ctest_build()
if(NOT (CC_NAME STREQUAL "msvc" AND CC_ARCH STREQUAL "arm"))
    ctest_test()
endif()
ctest_submit()

set(CTEST_CONFIGURATION_TYPE "Debug")

# Coverage
if(CC_NAME STREQUAL "gcc")
    find_program(CTEST_COVERAGE_COMMAND NAMES gcov-${CC_VERSION})
    if(NOT CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
    endif()
elseif(CC_NAME STREQUAL "clang")
    find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov-${CC_VERSION})
    if(NOT CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov)
    endif()
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} gcov")
    endif()
elseif(CC_NAME STREQUAL "xcode")
    find_program(CTEST_COVERAGE_COMMAND NAMES llvm-cov PATHS /Library/Developer/CommandLineTools/usr/bin/)
    if(CC_VERSION VERSION_GREATER 6.3 OR CC_VERSION VERSION_EQUAL 6.3)
        set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} gcov")
    endif()
elseif(CC_NAME STREQUAL "icc")
    set(CTEST_COVERAGE_COMMAND codecov)
    set(CTEST_COVERAGE_EXTRA_FLAGS "${CTEST_COVERAGE_EXTRA_FLAGS} -txtlcov")
elseif(CC_NAME STREQUAL "msvc" AND NOT CC_ARCH STREQUAL "arm")
    find_program(CTEST_COVERAGE_COMMAND NAMES OpenCppCoverage)   
endif()
if(CTEST_COVERAGE_COMMAND)
    if(CC_NAME STREQUAL "gcc" OR CC_NAME STREQUAL "clang" OR CC_NAME STREQUAL "xcode")
        set(CC_COVERAGE_FLAGS "--coverage ${CC_COVERAGE_FLAGS}")
    elseif(CC_NAME STREQUAL "icc")
        set(CC_COVERAGE_FLAGS " -prof-gen:srcpos -prof-dir=${CTEST_BINARY_DIRECTORY} ${CC_COVERAGE_FLAGS}")
    endif()
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-cov")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    ctest_configure(OPTIONS "-DCI_FLAGS=${CC_COVERAGE_FLAGS}")
    ctest_build()
    ctest_test()
    if(CC_NAME STREQUAL "msvc")
        exec_program(ctest ${CTEST_BINARY_DIRECTORY} ARGS -N OUTPUT_VARIABLE OCC_TESTS)
        set(OCC_ABORT 0)
        set(OCC_LASTTEST "")
        while(OCC_ABORT GREATER -1)
            string(REGEX MATCH "#[0-9]+: [^\r\n\t\\\\]+" OCC_TEST ${OCC_TESTS})
            string(REGEX REPLACE ${OCC_TEST} "" OCC_TESTS ${OCC_TESTS})
            string(REGEX MATCH "#[0-9]+: " OCC_TEMP ${OCC_TEST})
            string(REGEX REPLACE ${OCC_TEMP} "" OCC_TEST ${OCC_TEST})
            exec_program(${CTEST_COVERAGE_COMMAND} ${CTEST_BINARY_DIRECTORY}/Debug ARGS --sources ${CTEST_SOURCE_DIRECTORY}\\source --modules *${CI_BUILD_UUID}* --cover_children --export_type=cobertura -- ${OCC_TEST}.exe)
            file(READ ${CTEST_BINARY_DIRECTORY}/Debug/${OCC_TEST}Coverage.xml OCC_TESTXML)
            string(REGEX REPLACE "package name=[^ ]+\"" "package name=\"merged\"" OCC_TESTXML ${OCC_TESTXML})
            string(REGEX REPLACE "filename=[^ ]+\\source." "filename=\"source/" OCC_TESTXML ${OCC_TESTXML})
            string(REGEX REPLACE "<source>[^ ]+</source>" "<source>source</source>" OCC_TESTXML ${OCC_TESTXML})
            file(WRITE ${CTEST_BINARY_DIRECTORY}/Debug/${OCC_TEST}Coverage.xml ${OCC_TESTXML})
            string(FIND ${OCC_TESTS} "#" OCC_ABORT)
        endwhile()
        exec_program(python ${CTEST_SOURCE_DIRECTORY} ARGS ci-tools/merge_cobertura.py -p "${CTEST_BINARY_DIRECTORY}\\Debug" -o "${CTEST_BINARY_DIRECTORY}\\Debug\\coverage.xml")
        set(ENV{COBERTURADIR} "${CTEST_BINARY_DIRECTORY}\\Debug")
    endif()
    ctest_coverage()
    ctest_submit(PARTS Start Update Configure Build Test Coverage Upload Submit)
endif()

# Static analysis
if(CC_NAME STREQUAL "msvc" OR CC_NAME STREQUAL "clang")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-analyzer")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    if(CC_NAME STREQUAL "msvc")
        ctest_configure(OPTIONS "-DBUILD_TESTING=Off -DCI_FLAGS=/analyze")
    elseif(CC_NAME STREQUAL "clang")
        ctest_configure(OPTIONS "-DBUILD_TESTING=Off -DCI_FLAGS=--analyze")
    endif()
    ctest_build()
    ctest_submit(PARTS Start Update Configure Build Upload Submit)
endif()

# Dynamic analysis (Valgrind)
find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
if(CTEST_MEMORYCHECK_COMMAND)
    set(CTEST_MEMORYCHECK_TYPE "Valgrind")
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --track-origins=yes --leak-check=full --show-reachable=yes")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-valgrind")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    ctest_configure(OPTIONS "-DCI_FLAGS=-fno-omit-frame-pointer")
    ctest_build()
    ctest_test()
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit)
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "")
endif()

function(has_sanitizer has_sanitizer_arg has_sanitizer_retval)
    set(retval 0)
    if(UNIX)
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
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 4.8 OR CC_VERSION VERSION_EQUAL 4.8)
        if(CC_ASAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "AddressSanitizer")
        endif()
    endif()
elseif(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.1 OR CC_VERSION VERSION_EQUAL 3.1)
        if(CC_ASAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "AddressSanitizer")
        endif()
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "AddressSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1 check_initialization_order=1")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-asan")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    ctest_configure(OPTIONS "-DCI_FLAGS=-fsanitize=address -fno-omit-frame-pointer")
    ctest_build()
    ctest_test()
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit)
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
    ctest_configure(OPTIONS "-DCI_FLAGS=-fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer")
    ctest_build()
    ctest_test()
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit)
endif()

# Dynamic analysis(TSan)
# TSan was introduced in GCC 4.8 / Clang 3.2
# TSan works with non-pie builds starting GCC 5 / Clang 3.7
if(CC_NAME STREQUAL "gcc")
    if(CC_VERSION VERSION_GREATER 5 OR CC_VERSION VERSION_EQUAL 5)
        if(CC_TSAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "ThreadSanitizer")
            set(CI_UBUNTU 0)
            execute_process(COMMAND cat /etc/os-release COMMAND grep -c Ubuntu OUTPUT_VARIABLE CI_UBUNTU )
            if(CI_UBUNTU GREATER 0)
                set(CC_TSAN_FLAGS "-static-libtsan")
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
    ctest_configure(OPTIONS "-DCI_FLAGS=${CC_TSAN_FLAGS} -fsanitize=thread -fno-omit-frame-pointer")
    ctest_build()
    ctest_test()
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit)
endif()

# Dynamic analysis (UBSan)
# UBan was introduced in GCC 4.9 / Clang 3.3
# UBSan respects log_path starting Clang 3.7
if(CC_NAME STREQUAL "clang")
    if(CC_VERSION VERSION_GREATER 3.7 OR CC_VERSION VERSION_EQUAL 3.7)
        if(CC_UBSAN GREATER 0)
            set(CTEST_MEMORYCHECK_TYPE "UndefinedBehaviorSanitizer")
            set(CC_UBSAN_FLAGS "-fsanitize=undefined,integer -fno-sanitize=vptr,return")
        endif()
    endif()
endif()
if(CTEST_MEMORYCHECK_TYPE STREQUAL "UndefinedBehaviorSanitizer")
    set(CTEST_MEMORYCHECK_SANITIZER_OPTIONS "verbosity=1 print_stacktrace=1")
    set(CTEST_BUILD_NAME "${CI_BUILD_NAME}-ubsan")
    ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
    ctest_start(Continuous)
    ctest_update()
    ctest_read_custom_files(${CTEST_SOURCE_DIRECTORY})
    ctest_configure(OPTIONS "-DCI_FLAGS=${CC_UBSAN_FLAGS} -fno-omit-frame-pointer")
    ctest_build()
    ctest_test()
    ctest_memcheck()
    ctest_submit(PARTS Start Update Configure Build Test MemCheck Upload Submit)
endif()