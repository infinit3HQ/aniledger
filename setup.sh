#!/bin/bash

# AniLedger Setup Script
# This script helps you configure AniLedger for local development

set -e

echo "🎬 AniLedger Setup"
echo "=================="
echo ""

# Check if .env exists
if [ -f ".env" ]; then
    echo "✓ .env file already exists"
    source .env
else
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ Created .env file"
fi

# Check if ANILIST_CLIENT_ID is set
if [ -z "$ANILIST_CLIENT_ID" ] || [ "$ANILIST_CLIENT_ID" = "YOUR_CLIENT_ID_HERE" ]; then
    echo ""
    echo "⚠️  AniList Client ID not configured!"
    echo ""
    echo "To get your Client ID:"
    echo "1. Go to https://anilist.co/settings/developer"
    echo "2. Create a new API Client"
    echo "3. Set redirect URI to: aniledger://auth-callback"
    echo "4. Copy your Client ID"
    echo ""
    read -p "Enter your AniList Client ID (or press Enter to skip): " client_id
    
    if [ ! -z "$client_id" ]; then
        # Update .env file
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/ANILIST_CLIENT_ID=.*/ANILIST_CLIENT_ID=$client_id/" .env
        else
            # Linux
            sed -i "s/ANILIST_CLIENT_ID=.*/ANILIST_CLIENT_ID=$client_id/" .env
        fi
        echo "✓ Updated .env with your Client ID"
        export ANILIST_CLIENT_ID="$client_id"
    else
        echo "⚠️  Skipped Client ID configuration"
        echo "   You can manually edit .env later"
    fi
fi

echo ""
echo "📋 Configuration Summary"
echo "========================"
echo "Client ID: ${ANILIST_CLIENT_ID:-Not configured}"
echo ""

# Check if Xcode is installed
if command -v xcodebuild &> /dev/null; then
    echo "✓ Xcode is installed"
    
    # Offer to configure Xcode scheme
    echo ""
    echo "To use the Client ID in Xcode:"
    echo "1. Open the project: open AniLedger.xcodeproj"
    echo "2. Go to: Product → Scheme → Edit Scheme..."
    echo "3. Select 'Run' → 'Arguments' tab"
    echo "4. Add Environment Variable:"
    echo "   Name: ANILIST_CLIENT_ID"
    echo "   Value: $ANILIST_CLIENT_ID"
    echo ""
    read -p "Open project in Xcode now? (y/n): " open_xcode
    
    if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
        echo "Opening Xcode..."
        open AniLedger.xcodeproj
    fi
else
    echo "⚠️  Xcode not found"
    echo "   Please install Xcode from the App Store"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure the environment variable in Xcode (see above)"
echo "2. Build and run the project (Cmd+R)"
echo "3. Login with your AniList account"
echo ""
echo "For more information, see README.md"
