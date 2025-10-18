#!/bin/bash
# ������� �����: chmod +x ci.sh

# �������� ������ ��� ������ �������
set -e

echo "--- Starting CI Script for Linux/macOS ---"

# 1. ���������/�������� ��������
rm -rf build
mkdir -p build

# 2. ������� � �������
cd build

# 3. �������������� (Single-config � Ninja + Release)
echo "[STEP] Configuring project..."
cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release

# 4. ����������
echo "[STEP] Building project..."
cmake --build .

# 5. ������ �����
echo "[STEP] Running tests..."
ctest --output-on-failure

echo "--- CI SUCCEEDED ---"