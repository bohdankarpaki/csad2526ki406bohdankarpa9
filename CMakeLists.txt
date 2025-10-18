cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# ОНОВЛЕНО: Встановлюємо Release як тип збірки за замовчуванням
# Це хороший варіант, якщо ви майже завжди хочете Release-збірку
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
  message(STATUS "Build type not specified, defaulting to: ${CMAKE_BUILD_TYPE}")
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

set(gtest_force_shared_crt ON)
FetchContent_MakeAvailable(googletest)

add_executable(run_tests tests/unit_tests.cpp math_operations.cpp)
target_link_libraries(run_tests GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(run_tests)