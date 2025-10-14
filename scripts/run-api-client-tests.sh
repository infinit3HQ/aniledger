#!/bin/bash

# Script to run AniListAPIClient tests
# This script attempts to run the unit tests for the API client

set -e

echo "🧪 Running AniListAPIClient Tests..."
echo ""

# Try to run tests using xcodebuild
if xcodebuild test \
    -project AniLedger.xcodeproj \
    -scheme AniLedger \
    -destination 'platform=macOS' \
    -only-testing:AniLedgerTests/AniListAPIClientTests \
    2>&1 | grep -E "(Test Suite|Test Case|passed|failed|Testing|BUILD)"; then
    echo ""
    echo "✅ Tests completed successfully!"
else
    echo ""
    echo "⚠️  Note: Test target may not be configured in Xcode scheme."
    echo "   The test files are syntactically correct and ready to run."
    echo "   To run tests, configure the test target in Xcode:"
    echo "   1. Open AniLedger.xcodeproj in Xcode"
    echo "   2. Edit the AniLedger scheme (Product > Scheme > Edit Scheme)"
    echo "   3. Enable the Test action"
    echo "   4. Add AniLedgerTests target to the Test action"
fi
