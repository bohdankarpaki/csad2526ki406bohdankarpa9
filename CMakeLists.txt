cmake_minimum_required(VERSION 3.10)
project(csad2526KI404MaksymFedyna25)

set(CMAKE_CXX_STANDARD 20)

add_executable(csad2526KI404MaksymFedyna25 main.cpp
        math_operations.h
        math_operations.cpp)

# Enable testing
include(CTest)
enable_testing()

# Add GoogleTest
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/heads/main.zip
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Add test executable
add_executable(unit_tests tests/unit_tests.cpp math_operations.cpp)
target_link_libraries(unit_tests gtest_main)

include(GoogleTest)
gtest_discover_tests(unit_tests)