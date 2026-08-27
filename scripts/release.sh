#!/bin/bash

# ==============================================================================
# Local Release & Packaging Script for AniLedger
# Builds DMG on macOS, tags the release, and pushes to Git.
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$(grep -m1 "MARKETING_VERSION" "${PROJECT_DIR}/AniLedger.xcodeproj/project.pbxproj" | sed -e 's/[^0-9.]//g')

if [ -z "${VERSION}" ]; then
    VERSION="0.4.0"
fi

# Tag format matching repository convention (v.0.4)
TAG_NAME="v.${VERSION}"
REMOTE_NAME="INFINITEHQ"

echo "=================================================="
echo "🚀 Local Release & DMG Bundling for AniLedger v${VERSION}"
echo "🏷️ Git Tag: ${TAG_NAME}"
echo "🌐 Git Remote: ${REMOTE_NAME}"
echo "=================================================="

# 1. Build and package DMG locally on macOS
echo ""
echo "🔨 Step 1: Building macOS DMG locally..."
"${PROJECT_DIR}/scripts/build-dmg.sh"

# 2. Stage and commit changes if any
echo ""
echo "📝 Step 2: Committing release changes..."
if ! git diff-index --quiet HEAD --; then
    git add -A
    git commit -m "chore(release): Prepare v${VERSION} release"
fi

# 3. Create or update Git Tag
echo ""
echo "🏷️ Step 3: Creating Git tag ${TAG_NAME}..."
if git rev-parse "${TAG_NAME}" >/dev/null 2>&1; then
    git tag -d "${TAG_NAME}"
fi
git tag -a "${TAG_NAME}" -m "Release v${VERSION}"

# 4. Push branch and tag to remote
CURRENT_BRANCH=$(git branch --show-current)
echo ""
echo "📤 Step 4: Pushing branch '${CURRENT_BRANCH}' and tag '${TAG_NAME}' to ${REMOTE_NAME}..."
git push "${REMOTE_NAME}" "${CURRENT_BRANCH}"
git push "${REMOTE_NAME}" "${TAG_NAME}" --force

# 5. Upload DMG to GitHub Release if gh CLI is authenticated, or provide direct links
echo ""
echo "📦 Step 5: GitHub Release & DMG Upload"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "Creating release on GitHub with DMG attachments..."
    gh release create "${TAG_NAME}" \
        "${PROJECT_DIR}/dist"/*.dmg \
        --title "AniLedger v${VERSION}" \
        --notes "Release v${VERSION} - macOS native DMG installer" \
        --clobber
    echo "✅ GitHub Release published with DMG attached!"
else
    echo "💡 Note: GitHub CLI is not currently authenticated."
    echo "👉 To upload the DMG automatically, run: gh auth login"
    echo "   and re-run: gh release create ${TAG_NAME} dist/*.dmg --title \"AniLedger v${VERSION}\""
    echo ""
    echo "👉 Or drag-and-drop the generated DMG directly:"
    echo "   File: ${PROJECT_DIR}/dist/AniLedger-${VERSION}.dmg"
    echo "   URL:  https://github.com/infinit3HQ/aniledger/releases/new?tag=${TAG_NAME}"
fi

echo ""
echo "=================================================="
echo "🎉 Release v${VERSION} Complete!"
echo "=================================================="
