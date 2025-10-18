# Specify the minimum version of CMake required.
cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# ВАЖЛИВО: Цей блок вмикає статичне зв'язування (/MT) на Windows.
# Це вирішує вашу початкову помилку 0xc000007b.
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

# ВАЖЛИВО: Переконайтесь, що цей рядок видалено або закоментовано
# set(gtest_force_shared_crt ON)

FetchContent_MakeAvailable(googletest)

add_executable(run_tests tests/unit_tests.cpp math_operations.cpp)
target_link_libraries(run_tests GTest::gtest_main)

# --- ФІНАЛЬНИЙ БЛОК ТЕСТУВАННЯ ---

# ВАЖЛИВО: ВИДАЛІТЬ або закоментуйте ці два рядки.
# Вони є причиною помилки MSB3073.
# include(GoogleTest)
# gtest_discover_tests(run_tests)

# ВАЖЛИВО: ЗАЛИШІТЬ ТІЛЬКИ ЦЕЙ РЯДОК.
# Він правильно реєструє тест, не створюючи конфліктів при збірці.
add_test(NAME UnitTests COMMAND $<TARGET_FILE:run_tests>)