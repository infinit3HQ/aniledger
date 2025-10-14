# Configuration Guide

This guide explains how to securely configure AniLedger for development and deployment.

## Quick Start

### Automated Setup (Recommended)

Run the setup script:

```bash
./setup.sh
```

This will:
1. Create a `.env` file from the template
2. Prompt you for your AniList Client ID
3. Configure the environment
4. Optionally open the project in Xcode

### Manual Setup

If you prefer to configure manually, follow the steps below.

## Getting Your AniList Client ID

Before you can use AniLedger, you need to register an OAuth application with AniList:

1. **Go to AniList Developer Settings**
   - Visit: https://anilist.co/settings/developer
   - Log in with your AniList account

2. **Create a New Client**
   - Click "Create New Client"
   - Fill in the form:
     - **Name**: `AniLedger` (or your preferred name)
     - **Redirect URI**: `aniledger://auth-callback`
     - **Description**: Optional

3. **Save and Copy Client ID**
   - Click "Save"
   - You'll see both a **Client ID** and **Client Secret**
   - Copy **ONLY the Client ID** (ignore the Client Secret)
   - Keep this ID private!

**Important:** AniList provides a Client Secret, but you should NOT use it for this native application. Native apps cannot securely store secrets, and AniList's OAuth works without it. Client secrets are only for server-side applications.

## Configuration Methods

Choose one of the following methods to configure your Client ID:

### Method 1: Xcode Environment Variable (Recommended for Development)

This is the easiest method for local development in Xcode:

1. **Open the Project**
   ```bash
   open AniLedger.xcodeproj
   ```

2. **Edit the Scheme**
   - In Xcode menu: **Product → Scheme → Edit Scheme...**
   - Or press: `Cmd + <` (Command + Less Than)

3. **Add Environment Variable**
   - Select **"Run"** in the left sidebar
   - Click the **"Arguments"** tab
   - Under **"Environment Variables"**, click the **"+"** button
   - Add:
     - **Name**: `ANILIST_CLIENT_ID`
     - **Value**: Your actual Client ID (e.g., `12345`)

4. **Save**
   - Click **"Close"**
   - The environment variable is now set for all Xcode runs

**Pros:**
- ✓ Easy to set up in Xcode
- ✓ Persists across Xcode sessions
- ✓ Doesn't require terminal commands
- ✓ Scheme settings are user-specific (not committed)

**Cons:**
- ✗ Only works when running from Xcode
- ✗ Need to reconfigure if scheme is deleted

### Method 2: .env File (Recommended for Terminal)

This method is great if you run the app from the terminal or use command-line tools:

1. **Create .env File**
   ```bash
   cp .env.example .env
   ```

2. **Edit .env File**
   ```bash
   nano .env
   # or
   open -e .env
   ```

3. **Add Your Client ID**
   ```bash
   ANILIST_CLIENT_ID=your_actual_client_id
   ```

4. **Source Before Running**
   ```bash
   source .env && open AniLedger.xcodeproj
   ```

**Pros:**
- ✓ Works from terminal
- ✓ Easy to manage multiple environments
- ✓ Can be sourced in shell profile
- ✓ File is gitignored

**Cons:**
- ✗ Must source before each session
- ✗ Doesn't automatically work in Xcode

### Method 3: Shell Environment Variable

Set the environment variable in your shell:

1. **Temporary (Current Session Only)**
   ```bash
   export ANILIST_CLIENT_ID="your_actual_client_id"
   ```

2. **Permanent (Add to Shell Profile)**
   
   For **zsh** (default on macOS):
   ```bash
   echo 'export ANILIST_CLIENT_ID="your_actual_client_id"' >> ~/.zshrc
   source ~/.zshrc
   ```
   
   For **bash**:
   ```bash
   echo 'export ANILIST_CLIENT_ID="your_actual_client_id"' >> ~/.bash_profile
   source ~/.bash_profile
   ```

**Pros:**
- ✓ Available system-wide
- ✓ Works in terminal and Xcode
- ✓ Persists across sessions

**Cons:**
- ✗ Available to all applications
- ✗ Harder to manage multiple values
- ✗ Must restart Xcode to pick up changes

### Method 4: Xcode Build Configuration (Advanced)

For more complex setups, you can use Xcode build configurations:

1. **Create xcconfig File**
   ```bash
   echo 'ANILIST_CLIENT_ID = your_actual_client_id' > Config.xcconfig.local
   ```

2. **Add to .gitignore**
   ```bash
   echo 'Config.xcconfig.local' >> .gitignore
   ```

3. **Configure in Xcode**
   - Select project in navigator
   - Select target
   - Go to "Build Settings"
   - Search for "User-Defined"
   - Add: `ANILIST_CLIENT_ID = $(ANILIST_CLIENT_ID)`

**Pros:**
- ✓ Professional approach
- ✓ Supports multiple configurations
- ✓ Can be used in build scripts

**Cons:**
- ✗ More complex setup
- ✗ Requires Xcode configuration

## Verification

### Check Configuration

To verify your configuration is working:

1. **Run the App**
   - Build and run in Xcode (`Cmd + R`)
   - Or from terminal: `xcodebuild -project AniLedger.xcodeproj -scheme AniLedger`

2. **Check Console Output**
   - If configured correctly: No warnings
   - If not configured: You'll see:
     ```
     ⚠️ Warning: AniList Client ID not configured. Please update Config.swift with your client ID.
     ```

3. **Test Login**
   - Launch the app
   - Click "Login with AniList"
   - If configured correctly: Browser opens with AniList authorization
   - If not configured: Error message appears

### Troubleshooting

**Problem: "Client ID not configured" warning**

Solution:
- Verify environment variable is set: `echo $ANILIST_CLIENT_ID`
- Check Xcode scheme environment variables
- Restart Xcode after setting environment variables

**Problem: "Invalid client" error from AniList**

Solution:
- Verify Client ID is correct
- Check redirect URI is exactly: `aniledger://auth-callback`
- Ensure client is not deleted in AniList settings

**Problem: Environment variable not working in Xcode**

Solution:
- Quit and restart Xcode
- Check scheme settings (Product → Scheme → Edit Scheme)
- Try setting in both Run and Test schemes

## CI/CD Configuration

### GitHub Actions

```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Build
      env:
        ANILIST_CLIENT_ID: ${{ secrets.ANILIST_CLIENT_ID }}
      run: |
        xcodebuild -project AniLedger.xcodeproj \
                   -scheme AniLedger \
                   -destination 'platform=macOS' \
                   build
```

Add `ANILIST_CLIENT_ID` to repository secrets:
- Go to: Settings → Secrets and variables → Actions
- Click "New repository secret"
- Name: `ANILIST_CLIENT_ID`
- Value: Your Client ID

### GitLab CI

```yaml
build:
  stage: build
  script:
    - export ANILIST_CLIENT_ID=$ANILIST_CLIENT_ID
    - xcodebuild -project AniLedger.xcodeproj -scheme AniLedger build
  variables:
    ANILIST_CLIENT_ID: $ANILIST_CLIENT_ID
```

Add `ANILIST_CLIENT_ID` to CI/CD variables:
- Go to: Settings → CI/CD → Variables
- Add variable: `ANILIST_CLIENT_ID`
- Mark as "Protected" and "Masked"

## Security Best Practices

### Do's ✓

- ✓ Use environment variables for sensitive values
- ✓ Keep `.env` file in `.gitignore`
- ✓ Use different Client IDs for dev/staging/prod
- ✓ Rotate Client ID if exposed
- ✓ Use CI/CD secrets for automated builds
- ✓ Document configuration steps

### Don'ts ✗

- ✗ Never hardcode Client ID in source files
- ✗ Never commit `.env` file
- ✗ Never share your Client ID publicly
- ✗ Never use production Client ID in development
- ✗ Never log or print Client ID
- ✗ Never commit Xcode user data (`xcuserdata/`)

## Multiple Environments

If you need different configurations for different environments:

### Using .env Files

```bash
# Development
.env.development
ANILIST_CLIENT_ID=dev_client_id

# Staging
.env.staging
ANILIST_CLIENT_ID=staging_client_id

# Production
.env.production
ANILIST_CLIENT_ID=prod_client_id
```

Load the appropriate file:
```bash
source .env.development && open AniLedger.xcodeproj
```

### Using Xcode Schemes

1. Create multiple schemes (Development, Staging, Production)
2. Configure different environment variables for each scheme
3. Select appropriate scheme when building

## Additional Resources

- [AniList API Documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [OAuth 2.0 Guide](https://oauth.net/2/)
- [Xcode Environment Variables](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)
- [Security Best Practices](SECURITY.md)

## Getting Help

If you're having trouble with configuration:

1. Check this guide thoroughly
2. Review [SECURITY.md](SECURITY.md) for security guidelines
3. Check [README.md](README.md) for general setup
4. Open an issue on GitHub (without sharing your Client ID!)

## Summary

**Recommended Setup:**

1. Run `./setup.sh` for automated configuration
2. Or manually set environment variable in Xcode scheme
3. Verify configuration by running the app
4. Never commit your Client ID to version control

**Remember:** Your Client ID should be treated as sensitive information. Keep it private and secure!
