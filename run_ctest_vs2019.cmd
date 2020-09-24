refreshenv
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" amd64
if %ERRORLEVEL% neq 0 (
    rem Reset %ERRORLEVEL%
    ver > nul 
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
)
python ci-tools/run_ctest.py