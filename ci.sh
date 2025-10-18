#!/bin/bash
# Надайте права: chmod +x ci.sh

# Зупинити скрипт при першій помилці
set -e

echo "--- Starting CI Script for Linux/macOS ---"

# 1. Створення/очищення каталогу
rm -rf build
mkdir -p build

# 2. Перехід у каталог
cd build

# 3. Конфігурування (Single-config з Ninja + Release)
echo "[STEP] Configuring project..."
cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release

# 4. Білдування
echo "[STEP] Building project..."
cmake --build .

# 5. Запуск тестів
echo "[STEP] Running tests..."
ctest --output-on-failure

echo "--- CI SUCCEEDED ---"