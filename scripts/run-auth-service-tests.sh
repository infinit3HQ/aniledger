#!/bin/bash

# Script to run AuthenticationService tests
# This script attempts to run the AuthenticationService unit tests

echo "🧪 Running AuthenticationService Tests..."
echo "=========================================="
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please ensure Xcode is installed."
    exit 1
fi

# Try to run the tests
echo "Attempting to run tests..."
xcodebuild test \
    -project AniLedger.xcodeproj \
    -scheme AniLedger \
    -destination 'platform=macOS' \
    -only-testing:AniLedgerTests/AuthenticationServiceTests \
    2>&1 | tee /tmp/auth_test_output.log

# Check the result
if grep -q "Test Suite 'AuthenticationServiceTests' passed" /tmp/auth_test_output.log; then
    echo ""
    echo "✅ All AuthenticationService tests passed!"
    exit 0
elif grep -q "is not currently configured for the test action" /tmp/auth_test_output.log; then
    echo ""
    echo "⚠️  Test target not configured in Xcode scheme."
    echo ""
    echo "To configure the test target:"
    echo "1. Open AniLedger.xcodeproj in Xcode"
    echo "2. Go to Product > Scheme > Edit Scheme..."
    echo "3. Select 'Test' in the left sidebar"
    echo "4. Click '+' to add a test target"
    echo "5. Select 'AniLedgerTests'"
    echo "6. Click 'Close'"
    echo ""
    echo "Then run this script again or use Cmd+U in Xcode."
    exit 1
else
    echo ""
    echo "❌ Some tests failed. Check the output above for details."
    exit 1
fi
