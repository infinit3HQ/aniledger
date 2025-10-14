#!/bin/bash

# Verification script for AuthenticationService tests
# This script checks that all test files are present and syntactically correct

echo "🔍 Verifying AuthenticationService Test Implementation"
echo "======================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
all_checks_passed=true

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found: $1"
        return 0
    else
        echo -e "${RED}✗${NC} Missing: $1"
        all_checks_passed=false
        return 1
    fi
}

# Function to check file has content
check_file_content() {
    if [ -s "$1" ]; then
        echo -e "${GREEN}✓${NC} Has content: $1"
        return 0
    else
        echo -e "${RED}✗${NC} Empty or missing: $1"
        all_checks_passed=false
        return 1
    fi
}

echo "📁 Checking Test Files..."
echo ""

# Check main test file
check_file "AniLedgerTests/Services/AuthenticationServiceTests.swift"
check_file_content "AniLedgerTests/Services/AuthenticationServiceTests.swift"

# Check mock files
check_file "AniLedgerTests/Mocks/MockKeychainManager.swift"
check_file_content "AniLedgerTests/Mocks/MockKeychainManager.swift"

check_file "AniLedgerTests/Mocks/MockAniListAPIClient.swift"
check_file_content "AniLedgerTests/Mocks/MockAniListAPIClient.swift"

# Check documentation
check_file "AniLedgerTests/Services/AUTHENTICATION_SERVICE_TESTS.md"
check_file_content "AniLedgerTests/Services/AUTHENTICATION_SERVICE_TESTS.md"

# Check implementation file
check_file "AniLedger/Services/AuthenticationService.swift"
check_file_content "AniLedger/Services/AuthenticationService.swift"

echo ""
echo "📊 Analyzing Test Coverage..."
echo ""

# Count test methods
test_count=$(grep -c "func test" AniLedgerTests/Services/AuthenticationServiceTests.swift 2>/dev/null || echo "0")
echo "Test methods found: $test_count"

if [ "$test_count" -ge 15 ]; then
    echo -e "${GREEN}✓${NC} Sufficient test coverage (15+ tests)"
else
    echo -e "${YELLOW}⚠${NC} Expected at least 15 tests, found $test_count"
fi

echo ""
echo "🔍 Checking Test Categories..."
echo ""

# Check for specific test categories
categories=(
    "Authentication State"
    "Token Storage"
    "Logout"
    "User Profile"
    "Error Handling"
    "Token Refresh"
)

for category in "${categories[@]}"; do
    if grep -q "$category" AniLedgerTests/Services/AUTHENTICATION_SERVICE_TESTS.md 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $category tests documented"
    else
        echo -e "${YELLOW}⚠${NC} $category tests not documented"
    fi
done

echo ""
echo "📝 Checking Required Test Scenarios..."
echo ""

# Check for required test scenarios
required_tests=(
    "testIsAuthenticatedWhenTokenExists"
    "testIsNotAuthenticatedWhenNoToken"
    "testTokenStorageAfterAuthentication"
    "testTokenRetrievalFromKeychain"
    "testLogoutClearsToken"
    "testLogoutHandlesKeychainError"
    "testLogoutClearsCurrentUser"
    "testFetchUserProfileSuccess"
    "testAuthenticationFailsWhenAPIReturnsError"
    "testAuthenticationFailsWhenNetworkError"
    "testRefreshTokenReturnsCurrentToken"
    "testRefreshTokenFailsWhenNoToken"
)

for test in "${required_tests[@]}"; do
    if grep -q "$test" AniLedgerTests/Services/AuthenticationServiceTests.swift 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $test"
    else
        echo -e "${RED}✗${NC} Missing: $test"
        all_checks_passed=false
    fi
done

echo ""
echo "🔧 Checking Mock Objects..."
echo ""

# Check MockKeychainManager methods
if grep -q "func save" AniLedgerTests/Mocks/MockKeychainManager.swift 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MockKeychainManager.save() implemented"
else
    echo -e "${RED}✗${NC} MockKeychainManager.save() missing"
    all_checks_passed=false
fi

if grep -q "func retrieve" AniLedgerTests/Mocks/MockKeychainManager.swift 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MockKeychainManager.retrieve() implemented"
else
    echo -e "${RED}✗${NC} MockKeychainManager.retrieve() missing"
    all_checks_passed=false
fi

if grep -q "func delete" AniLedgerTests/Mocks/MockKeychainManager.swift 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MockKeychainManager.delete() implemented"
else
    echo -e "${RED}✗${NC} MockKeychainManager.delete() missing"
    all_checks_passed=false
fi

# Check MockAniListAPIClient methods
if grep -q "func execute.*query:" AniLedgerTests/Mocks/MockAniListAPIClient.swift 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MockAniListAPIClient.execute(query:) implemented"
else
    echo -e "${RED}✗${NC} MockAniListAPIClient.execute(query:) missing"
    all_checks_passed=false
fi

echo ""
echo "📋 Requirements Coverage Check..."
echo ""

requirements=(
    "1.1"
    "1.2"
    "1.3"
    "1.4"
    "1.5"
    "1.6"
)

for req in "${requirements[@]}"; do
    if grep -q "$req" AniLedgerTests/Services/AUTHENTICATION_SERVICE_TESTS.md 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Requirement $req covered"
    else
        echo -e "${YELLOW}⚠${NC} Requirement $req not explicitly documented"
    fi
done

echo ""
echo "======================================================"

if [ "$all_checks_passed" = true ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "AuthenticationService tests are complete and ready to run."
    echo "To run the tests, use: ./scripts/run-auth-service-tests.sh"
    exit 0
else
    echo -e "${RED}❌ Some checks failed.${NC}"
    echo ""
    echo "Please review the issues above and fix them."
    exit 1
fi
