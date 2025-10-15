# Specify the minimum version of CMake required.
cmake_minimum_required(VERSION 3.14) # FetchContent works best with 3.11+, 3.14 is a good baseline
project(HelloWorld CXX)

# Set the C++ standard to C++17 and make it a requirement.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ----------------- Main Executable -----------------
# Add the source files for your main application.
add_executable(hello main.cpp math_operations.cpp)


# ----------------- Testing -----------------
# Enable testing with CTest.
enable_testing()

# Include the FetchContent module to handle external dependencies.
include(FetchContent)

# Declare the Google Test dependency from its GitHub repository.
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        main # Use the main branch for the latest version
)

# Make the dependency available to your project.
# This will download and configure GTest.
FetchContent_MakeAvailable(googletest)

# Add a new executable for your tests.
add_executable(run_tests tests/unit_tests.cpp math_operations.cpp)

# Link the test executable against Google Test.
# GTest::gtest_main links both the library and its main function.
target_link_libraries(run_tests GTest::gtest_main)

# Add the test to CTest for easy execution.
add_test(NAME MathTests COMMAND run_tests)