# Specify the minimum version of CMake required.
cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# Цей блок для статичного зв'язування (ЗАЛИШТЕ ЙОГО)
if(MSVC)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Set the C++ standard to C++17 and make it a requirement.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ----------------- Main Executable -----------------
add_executable(hello main.cpp math_operations.cpp)


# ----------------- Testing -----------------
enable_testing()
include(FetchContent)

FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        main
)

# ОНОВЛЕНО: ВИДАЛІТЬ ЦЕЙ РЯДОК
# set(gtest_force_shared_crt ON)  <-- ВИДАЛІТЬ ЦЕ

# Make the dependency available to your project.
FetchContent_MakeAvailable(googletest)

# Add a new executable for your tests.
add_executable(run_tests tests/unit_tests.cpp math_operations.cpp)

# Link the test executable against Google Test.
target_link_libraries(run_tests GTest::gtest_main)

# Include the GoogleTest module and automatically discover tests.
include(GoogleTest)
gtest_discover_tests(run_tests)