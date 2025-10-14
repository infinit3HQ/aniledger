# Security Guidelines for AniLedger

## Overview

This document outlines security best practices for developing and deploying AniLedger, particularly regarding sensitive configuration values like API keys and OAuth client IDs.

## Sensitive Configuration Management

### What Should NOT Be Committed

The following sensitive values should **NEVER** be hardcoded in source files or committed to version control:

- ✗ AniList OAuth Client ID
- ✗ API keys or secrets
- ✗ Access tokens
- ✗ User credentials
- ✗ Private keys or certificates

### Secure Configuration Methods

AniLedger uses environment variables to keep sensitive configuration secure:

#### 1. Environment Variables (Recommended)

**For Local Development (Xcode):**
1. Product → Scheme → Edit Scheme...
2. Run → Arguments → Environment Variables
3. Add: `ANILIST_CLIENT_ID` = `your_client_id`

**For Terminal/CI:**
```bash
export ANILIST_CLIENT_ID="your_client_id"
```

**For .env File:**
```bash
# Create .env file (gitignored)
echo "ANILIST_CLIENT_ID=your_client_id" > .env

# Source before running
source .env && open AniLedger.xcodeproj
```

#### 2. Keychain (For Runtime Secrets)

Sensitive runtime data like access tokens are stored in the macOS Keychain:

```swift
// Storing tokens securely
try keychainManager.save(token: accessToken, for: "anilist_access_token")

// Retrieving tokens
let token = try keychainManager.retrieve(for: "anilist_access_token")
```

### Files Protected by .gitignore

The following files are automatically excluded from version control:

```
# Sensitive configuration
Config.local.swift
.env
.env.local
*.xcconfig.local

# User-specific Xcode settings
xcuserdata/
*.xcuserstate
```

## OAuth Security

### AniList OAuth Flow

AniLedger uses OAuth 2.0 Authorization Code flow for secure authentication:

1. **Authorization Request**: User is redirected to AniList
2. **User Authorization**: User approves the app
3. **Authorization Code**: AniList redirects back with a code
4. **Token Exchange**: App exchanges code for access token
5. **Secure Storage**: Token is stored in Keychain

### OAuth Configuration

- **Client ID**: Public identifier (still should not be committed for privacy)
- **Redirect URI**: `aniledger://auth-callback` (registered with AniList)
- **Client Secret**: **NOT USED** - AniList provides a client secret, but it should NOT be used in native apps
  - Native apps cannot securely store secrets (can be extracted via reverse engineering)
  - AniList's OAuth implementation works without client secret for native apps
  - Using Authorization Code flow without client secret is the correct approach
  - Client secrets are only for server-side/web applications
- **Token Storage**: Access tokens stored in macOS Keychain

### Security Best Practices

1. **Never log tokens**: Tokens should never appear in logs
2. **Use HTTPS**: All API requests use HTTPS
3. **Token expiration**: Tokens expire and must be refreshed
4. **Secure storage**: Use Keychain for all sensitive data
5. **Clear on logout**: Tokens are deleted from Keychain on logout

## Data Security

### Local Data Storage

- **Core Data**: Used for caching anime data locally
- **Encryption**: macOS provides file-level encryption
- **Data Cleanup**: Users can clear local data on logout
- **No Sensitive Data**: Only anime metadata is cached locally

### Network Security

- **HTTPS Only**: All network requests use HTTPS
- **Certificate Pinning**: Consider implementing for production
- **Rate Limiting**: Respects AniList API rate limits
- **Error Handling**: Network errors don't expose sensitive data

## Code Security

### Input Validation

```swift
// Validate user input
guard !username.isEmpty else {
    throw ValidationError.emptyUsername
}

// Sanitize URLs
guard let url = URL(string: urlString),
      url.scheme == "https" else {
    throw ValidationError.invalidURL
}
```

### Error Handling

```swift
// Don't expose sensitive data in errors
catch {
    // ✗ Bad: Exposes token
    print("Failed to authenticate with token: \(token)")
    
    // ✓ Good: Generic error message
    print("Authentication failed: \(error.localizedDescription)")
}
```

### Secure Coding Practices

1. **No hardcoded secrets**: Use environment variables
2. **Validate all input**: Never trust user input
3. **Use type safety**: Leverage Swift's type system
4. **Handle errors gracefully**: Don't expose internal details
5. **Minimize permissions**: Request only necessary permissions

## Deployment Security

### For Contributors

If you're contributing to AniLedger:

1. **Never commit your Client ID**: Use environment variables
2. **Review changes**: Check for accidentally committed secrets
3. **Use .gitignore**: Ensure sensitive files are excluded
4. **Test locally**: Verify your changes don't expose secrets

### For Maintainers

If you're maintaining a fork or deployment:

1. **Rotate secrets**: Change Client ID if exposed
2. **Use CI secrets**: Store secrets in CI/CD environment
3. **Review PRs**: Check for security issues
4. **Update dependencies**: Keep dependencies up to date

### For End Users

If you're building from source:

1. **Get your own Client ID**: Don't use someone else's
2. **Keep it private**: Don't share your Client ID
3. **Secure your machine**: Use FileVault encryption
4. **Regular updates**: Keep the app updated

## Incident Response

### If a Secret is Exposed

If you accidentally commit a secret:

1. **Rotate immediately**: Get a new Client ID from AniList
2. **Update configuration**: Use the new Client ID
3. **Revoke old secret**: Delete the old client in AniList settings
4. **Clean git history**: Use `git filter-branch` or BFG Repo-Cleaner
5. **Notify users**: If it's a public repository

### Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT open a public issue**
2. **Contact maintainers privately**
3. **Provide details**: Steps to reproduce, impact, etc.
4. **Allow time to fix**: Give maintainers time before disclosure

## Compliance

### Privacy

- **No tracking**: AniLedger doesn't track users
- **No analytics**: No usage data is collected
- **Local-first**: Data stays on your device
- **User control**: Users can delete all data

### Data Handling

- **Minimal data**: Only necessary data is stored
- **User consent**: OAuth requires user authorization
- **Data portability**: Users can export their data
- **Right to deletion**: Users can clear all local data

## Security Checklist

### Before Committing

- [ ] No hardcoded secrets in code
- [ ] Sensitive files in .gitignore
- [ ] Environment variables documented
- [ ] No tokens in logs or comments
- [ ] Error messages don't expose secrets

### Before Releasing

- [ ] All dependencies updated
- [ ] Security audit completed
- [ ] OAuth flow tested
- [ ] Token storage verified
- [ ] Data cleanup tested

### For Production

- [ ] Use production Client ID
- [ ] Enable certificate pinning
- [ ] Implement rate limiting
- [ ] Add crash reporting (without sensitive data)
- [ ] Regular security updates

## Resources

### Documentation

- [AniList API Documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

### Tools

- [git-secrets](https://github.com/awslabs/git-secrets) - Prevent committing secrets
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) - Remove secrets from history
- [detect-secrets](https://github.com/Yelp/detect-secrets) - Detect secrets in code

## Conclusion

Security is a shared responsibility. By following these guidelines, we can ensure that AniLedger remains secure for all users while maintaining an open-source codebase.

**Remember**: When in doubt, use environment variables and never commit secrets!
