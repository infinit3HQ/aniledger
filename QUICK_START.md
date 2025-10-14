# Quick Start Guide

Get AniLedger running in 5 minutes!

## Prerequisites

- macOS 12.0 or later
- Xcode 14.0 or later
- AniList account

## Setup Steps

### 1. Get AniList Client ID (2 minutes)

1. Go to https://anilist.co/settings/developer
2. Click "Create New Client"
3. Fill in:
   - Name: `AniLedger`
   - Redirect URI: `aniledger://auth-callback`
4. Click "Save" and copy your Client ID

### 2. Configure Project (1 minute)

**Option A: Automated (Recommended)**
```bash
./setup.sh
```

**Option B: Manual**
```bash
# In Xcode:
# Product → Scheme → Edit Scheme...
# Run → Arguments → Environment Variables
# Add: ANILIST_CLIENT_ID = your_client_id
```

### 3. Build and Run (2 minutes)

```bash
open AniLedger.xcodeproj
# Press Cmd+R to build and run
```

## Verification

✅ App launches without warnings
✅ "Login with AniList" button works
✅ Browser opens for authorization
✅ Redirects back to app after login

## Troubleshooting

**Problem:** "Client ID not configured" warning

**Solution:**
```bash
# Check if environment variable is set
echo $ANILIST_CLIENT_ID

# If empty, set it in Xcode scheme or run:
export ANILIST_CLIENT_ID="your_client_id"
```

**Problem:** "Invalid client" error

**Solution:**
- Verify Client ID is correct
- Check redirect URI is exactly: `aniledger://auth-callback`

## Next Steps

- 📖 Read [CONFIGURATION.md](CONFIGURATION.md) for detailed setup
- 🔒 Review [SECURITY.md](SECURITY.md) for security guidelines
- 📚 Check [README.md](README.md) for full documentation

## Quick Commands

```bash
# Run setup script
./setup.sh

# Set environment variable
export ANILIST_CLIENT_ID="your_client_id"

# Build from terminal
xcodebuild -project AniLedger.xcodeproj -scheme AniLedger build

# Clean build
xcodebuild clean

# Run tests
xcodebuild test -project AniLedger.xcodeproj -scheme AniLedger
```

## Support

Having issues? Check:
1. [CONFIGURATION.md](CONFIGURATION.md) - Detailed configuration guide
2. [SECURITY.md](SECURITY.md) - Security best practices
3. GitHub Issues - Report bugs or ask questions

---

**Remember:** Never commit your Client ID to version control!
