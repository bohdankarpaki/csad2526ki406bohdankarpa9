#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting CI Build and Test ---"
echo

# Create a build directory if it doesn't exist
echo "[STEP] Creating build directory..."
mkdir -p build

# Navigate into the build directory
cd build

# Configure the project using CMake and the Ninja generator
echo
echo "[STEP] Configuring project..."
cmake .. -G "Ninja"

# Build the project
echo
echo "[STEP] Building project..."
cmake --build .

# Run the tests with CTest
echo
echo "[STEP] Running tests..."
ctest --output-on-failure

echo
echo "--- CI SUCCEEDED ---"