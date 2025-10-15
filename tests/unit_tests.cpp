#include "gtest/gtest.h"
#include "../math_operations.h" // Include the header for the function we are testing

// Test suite for MathOperations
// TEST(TestSuiteName, TestCaseName)
TEST(MathOperationsTest, BasicAddition) {
    // Check if add(2, 3) returns 5.
    ASSERT_EQ(add(2, 3), 5);
}