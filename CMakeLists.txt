# Встановлюємо мінімальну версію CMake
cmake_minimum_required(VERSION 3.14)
project(HelloWorld CXX)

# --- Глобальні налаштування збірки ---
# Встановлюємо стандарт C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Важливо: Встановлюємо статичне зв'язування для MSVC (Windows)
# Це вбудовує бібліотеки в .exe і вирішує проблему з DLL
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# --- Створення спільної бібліотеки ---
# Це дозволяє уникнути дублювання коду
add_library(math_lib math_operations.cpp)

# --- Основна програма ---
add_executable(hello main.cpp)
target_link_libraries(hello math_lib)

# --- Налаштування тестування ---
enable_testing()
include(FetchContent)

# Завантажуємо Google Test
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        main
)
FetchContent_MakeAvailable(googletest)

# Створюємо виконуваний файл для тестів
add_executable(run_tests tests/unit_tests.cpp)
target_link_libraries(run_tests GTest::gtest_main math_lib)

# Автоматично знаходимо та додаємо тести
include(GoogleTest)
gtest_discover_tests(run_tests)