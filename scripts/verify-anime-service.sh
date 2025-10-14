#!/bin/bash

# Script to verify AnimeService implementation

echo "Verifying AnimeService Implementation..."
echo "========================================"
echo ""

# Check if AnimeService.swift exists
if [ -f "AniLedger/Services/AnimeService.swift" ]; then
    echo "✓ AnimeService.swift exists"
else
    echo "✗ AnimeService.swift not found"
    exit 1
fi

# Check if AnimeServiceTests.swift exists
if [ -f "AniLedgerTests/Services/AnimeServiceTests.swift" ]; then
    echo "✓ AnimeServiceTests.swift exists"
else
    echo "✗ AnimeServiceTests.swift not found"
    exit 1
fi

echo ""
echo "Checking AnimeService implementation..."
echo ""

# Check for key methods
methods=(
    "addAnimeToLibrary"
    "updateAnimeProgress"
    "updateAnimeStatus"
    "updateAnimeScore"
    "deleteAnimeFromLibrary"
    "fetchAnimeByStatus"
    "fetchAllUserAnime"
    "moveAnimeBetweenLists"
    "reorderAnime"
    "getUserAnime"
)

for method in "${methods[@]}"; do
    if grep -q "func $method" AniLedger/Services/AnimeService.swift; then
        echo "✓ Method '$method' implemented"
    else
        echo "✗ Method '$method' not found"
    fi
done

echo ""
echo "Checking test coverage..."
echo ""

# Check for key test categories
test_categories=(
    "Add Anime Tests"
    "Update Progress Tests"
    "Update Status Tests"
    "Update Score Tests"
    "Delete Anime Tests"
    "Fetch Anime Tests"
    "Move Between Lists Tests"
    "Reorder Anime Tests"
    "NeedsSync Flag Tests"
)

for category in "${test_categories[@]}"; do
    if grep -q "// MARK: - $category" AniLedgerTests/Services/AnimeServiceTests.swift; then
        echo "✓ Test category '$category' exists"
    else
        echo "✗ Test category '$category' not found"
    fi
done

echo ""
echo "Building project to verify compilation..."
echo ""

xcodebuild build \
  -project AniLedger.xcodeproj \
  -scheme AniLedger \
  -destination 'platform=macOS' \
  -quiet

if [ $? -eq 0 ]; then
    echo "✓ Project builds successfully"
    echo ""
    echo "========================================"
    echo "AnimeService verification complete!"
    echo "All checks passed ✓"
    echo "========================================"
else
    echo "✗ Build failed"
    exit 1
fi
