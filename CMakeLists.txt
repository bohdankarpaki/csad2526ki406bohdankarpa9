# Specify the minimum version of CMake required.
cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# Set the C++ standard to C++17 and make it a requirement.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MINGW)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
endif()

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
  GIT_TAG        main
)

# ADD THIS LINE to force GTest to use the same runtime library as your project.
set(gtest_force_shared_crt ON)

# Make the dependency available to your project.
FetchContent_MakeAvailable(googletest)

# Add a new executable for your tests.
add_executable(run_tests tests/unit_tests.cpp math_operations.cpp)

# Link the test executable against Google Test.
target_link_libraries(run_tests GTest::gtest_main)

# Include the GoogleTest module and automatically discover tests.
include(GoogleTest)
gtest_discover_tests(run_tests)
