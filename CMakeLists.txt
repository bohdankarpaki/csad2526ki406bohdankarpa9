# Specify the minimum version of CMake required.
cmake_minimum_required(VERSION 3.10)

# Set the project name and language.
project(HelloWorld CXX)

# Set the C++ standard to C++17 and make it a requirement.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the executable target named "hello" from the source file "main.cpp".
add_executable(hello main.cpp)