@echo off
REM Stop execution if any command fails
setlocal enabledelayedexpansion
goto start
:fail
exit /b 1
:start

REM Remove build directory if it exists
if exist build (
    rmdir /s /q build
    if exist build goto fail
)

REM Create a new build directory
mkdir build
if errorlevel 1 goto fail
cd build
if errorlevel 1 goto fail

REM Configure the project
cmake ..
if errorlevel 1 goto fail

REM Build the project
cmake --build .
if errorlevel 1 goto fail

REM Run tests
ctest
if errorlevel 1 goto fail

endlocal
