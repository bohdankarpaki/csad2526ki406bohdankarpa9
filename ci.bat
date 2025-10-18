@echo off
setlocal

echo --- Starting CI Script for Windows ---

REM 1. ���������/�������� ��������
if exist build rmdir /s /q build
mkdir build
if errorlevel 1 goto fail

REM 2. ������� � �������
cd build
if errorlevel 1 goto fail

REM 3. �������������� (Multi-config + 32-bit ��� ��������)
echo [STEP] Configuring project...
cmake .. -A Win32
if errorlevel 1 goto fail

REM 4. ���������� (ҳ���� 'ALL_BUILD', ��� ���������� 'RUN_TESTS' �� ��� �����)
echo [STEP] Building project...
cmake --build . --config Release --target ALL_BUILD
if errorlevel 1 goto fail

REM 5. ������ ����� (������, ���� �����)
echo [STEP] Running tests...
ctest --output-on-failure -C Release
if errorlevel 1 goto fail

echo.
echo --- CI SUCCEEDED ---
goto end

:fail
echo.
echo !!! CI FAILED !!!
exit /b 1

:end
exit /b 0