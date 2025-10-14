#!/bin/bash

# Script to run AnimeService tests

echo "Running AnimeService Tests..."
echo "=============================="

xcodebuild test \
  -project AniLedger.xcodeproj \
  -scheme AniLedger \
  -destination 'platform=macOS' \
  -only-testing:AniLedgerTests/AnimeServiceTests \
  2>&1 | grep -E "(Test Suite|Test Case|passed|failed|Executed)" | tail -100

echo ""
echo "Test run complete!"
