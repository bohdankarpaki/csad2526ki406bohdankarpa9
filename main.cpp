#include <iostream>
#include "math_operations.h" // Include your new header

int main() {
    int result = add(5, 3);
    std::cout << "Hello, World!" << std::endl;
    std::cout << "The result of 5 + 3 is: " << result << std::endl;
    std::cout << "Press Enter to exit..." << std::endl;
    std::cin.get(); // Чекає, поки користувач натисне Enter
    return 0;
}