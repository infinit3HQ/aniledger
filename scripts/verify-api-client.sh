#!/bin/bash

# Script to verify AniList API Client implementation
# This script builds the project to ensure the API client compiles correctly

set -e

echo "🔍 Verifying AniList API Client implementation..."
echo ""

# Check if required files exist
echo "✓ Checking for required files..."
files=(
    "AniLedger/Services/AniListAPIClient.swift"
    "AniLedger/Models/KiroError.swift"
    "AniLedger/GraphQL/GraphQLProtocols.swift"
    "AniLedger/GraphQL/GraphQLQueries.swift"
    "AniLedger/GraphQL/GraphQLMutations.swift"
    "AniLedger/GraphQL/GraphQLResponseModels.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (missing)"
        exit 1
    fi
done

echo ""
echo "✓ Building project..."
xcodebuild -project AniLedger.xcodeproj -scheme AniLedger -configuration Debug build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "  ✓ Build succeeded"
else
    echo "  ✗ Build failed"
    exit 1
fi

echo ""
echo "✅ AniList API Client implementation verified successfully!"
echo ""
echo "📝 Next steps:"
echo "  1. Add a test target to the Xcode project (see AniLedgerTests/README.md)"
echo "  2. Run the unit tests to verify functionality"
echo "  3. Integrate the API client with the Authentication Service"
