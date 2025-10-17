# Встановлюємо мінімальну версію CMake
cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# Встановлюємо стандарт C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Створюємо бібліотеку з логікою
add_library(math_lib math_operations.cpp)

# Створюємо основну програму
add_executable(hello main.cpp)
target_link_libraries(hello math_lib)

# --- Налаштування тестування ---
enable_testing()
include(FetchContent)

# Завантажуємо Google Test
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        release-1.14.0 # Використовуємо стабільний реліз
)
FetchContent_MakeAvailable(googletest)

# Створюємо виконуваний файл для тестів
add_executable(run_tests tests/unit_tests.cpp)
target_link_libraries(run_tests GTest::gtest_main math_lib)

# Автоматично знаходимо та додаємо тести
include(GoogleTest)
gtest_discover_tests(run_tests)