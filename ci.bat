@echo off
setlocal

echo --- Starting CI Script for Windows ---

REM 1. Створення/очищення каталогу
if exist build rmdir /s /q build
mkdir build
if errorlevel 1 goto fail

REM 2. Перехід у каталог
cd build
if errorlevel 1 goto fail

REM 3. Конфігурування (Multi-config + 32-bit для сумісності)
echo [STEP] Configuring project...
cmake .. -A Win32
if errorlevel 1 goto fail

REM 4. Білдування (Тільки 'ALL_BUILD', щоб пропустити 'RUN_TESTS' під час збірки)
echo [STEP] Building project...
cmake --build . --config Release --target ALL_BUILD
if errorlevel 1 goto fail

REM 5. Запуск тестів (Окремо, після збірки)
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