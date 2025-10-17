#!/bin/bash
set -e

# Remove build directory if it exists
if [ -d "build" ]; then
  rm -rf build
fi

# Create a new build directory
mkdir build
cd build

echo "--- Running Tests ---"
# Configure the project
cmake ..

# Build the project
cmake --build .

# Run tests
ctest

echo "--- CI Script Finished Successfully ---"