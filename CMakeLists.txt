# Specify the minimum version of CMake required.
cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# Statically link the C++ runtime library to avoid missing DLL issues on Windows.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Set the C++ standard to C++17.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ----------------- Shared Library -----------------
# Create a library from your shared code to avoid compiling it multiple times.
add_library(math_lib math_operations.cpp)

# ----------------- Main Executable -----------------
# Define the main executable and link it to your library.
add_executable(hello main.cpp)
target_link_libraries(hello math_lib)

# ----------------- Testing -----------------
enable_testing()
include(FetchContent)

# Declare and fetch Google Test.
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        main
)
FetchContent_MakeAvailable(googletest)

# Define the test executable and link it to Google Test and your library.
add_executable(run_tests tests/unit_tests.cpp)
target_link_libraries(run_tests GTest::gtest_main math_lib)

# Include the GoogleTest module and automatically discover tests.
include(GoogleTest)
gtest_discover_tests(run_tests)