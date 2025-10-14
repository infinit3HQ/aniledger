# Why AniLedger Doesn't Use Client Secret

## TL;DR

AniList provides both a **Client ID** and **Client Secret**, but AniLedger **only uses the Client ID**. This is the correct and secure approach for native/desktop applications.

## The Question

When you create an API client on AniList, you receive:
- ✅ **Client ID**: Used by AniLedger
- ❌ **Client Secret**: NOT used by AniLedger

Why don't we use the Client Secret?

## The Answer

### Native Apps Cannot Keep Secrets

**The fundamental problem:**
- Native applications (desktop, mobile) are distributed to end users
- The application binary is on the user's computer
- Anyone with the binary can extract embedded secrets through reverse engineering
- Tools exist to decompile, disassemble, and inspect application binaries

**Example attack:**
```bash
# Extract strings from binary
strings AniLedger.app/Contents/MacOS/AniLedger | grep -i secret

# Decompile the binary
hopper -e AniLedger.app/Contents/MacOS/AniLedger

# Result: Client secret is exposed
```

### OAuth 2.0 for Native Apps

The OAuth 2.0 specification (RFC 8252) explicitly addresses this:

> **Native applications** are public clients and therefore unable to use client secrets.

**Recommended approaches for native apps:**
1. **Authorization Code Flow without Client Secret** ← AniLedger uses this
2. **PKCE (Proof Key for Code Exchange)** - Additional security layer
3. **Implicit Flow** - Less secure, not recommended

### AniList's Implementation

AniList's OAuth implementation **supports native apps** by:
- ✅ Accepting token requests without client secret
- ✅ Validating the redirect URI instead
- ✅ Using the authorization code as proof of authorization

**Current AniLedger token request:**
```swift
let body: [String: Any] = [
    "grant_type": "authorization_code",
    "client_id": clientId,           // ✅ Used
    "redirect_uri": redirectUri,      // ✅ Used for validation
    "code": code                      // ✅ Proof of authorization
    // "client_secret": secret        // ❌ NOT included
]
```

This works perfectly and is secure for native apps.

### Security Through Redirect URI

Instead of relying on client secret, security is maintained through:

1. **Redirect URI Validation**
   - The redirect URI must match exactly what's registered with AniList
   - Only AniLedger can handle `aniledger://auth-callback`
   - Other apps cannot intercept the authorization code

2. **Authorization Code**
   - Single-use code that expires quickly
   - Can only be exchanged once for a token
   - Tied to the specific authorization request

3. **User Authorization**
   - User must explicitly approve the app
   - User can revoke access at any time
   - Tokens expire and must be refreshed

### When Client Secrets ARE Appropriate

Client secrets should be used for:

**✅ Server-Side Applications**
```
User → Web Browser → Your Server (has secret) → AniList API
```
- Secret stays on your server
- Users never see the secret
- Can be rotated without redistributing code

**✅ Backend Services**
```
Your Backend Service (has secret) → AniList API
```
- No user interaction
- Secret stored in secure environment
- Can use environment variables, secret managers, etc.

**❌ Native/Desktop Applications**
```
User → Native App (secret exposed) → AniList API
```
- Secret is in the app binary
- Users can extract the secret
- Cannot be rotated without app update
- Provides no real security

### Comparison

| Aspect | With Client Secret | Without Client Secret |
|--------|-------------------|----------------------|
| **Security in Native App** | ❌ False sense of security | ✅ Honest about limitations |
| **Secret Extraction** | ❌ Possible via reverse engineering | ✅ N/A - no secret to extract |
| **Secret Rotation** | ❌ Requires app update | ✅ N/A - no secret to rotate |
| **OAuth Compliance** | ❌ Violates RFC 8252 | ✅ Follows RFC 8252 |
| **AniList Support** | ✅ Works but unnecessary | ✅ Works and recommended |
| **Open Source** | ❌ Secret exposed in code | ✅ No secret to expose |

### Real-World Examples

**Apps that DON'T use client secrets (correctly):**
- Twitter for iOS/Android
- GitHub Desktop
- Spotify Desktop
- Discord Desktop
- Most OAuth-enabled native apps

**Why they don't:**
- They follow OAuth 2.0 best practices
- They understand native apps can't keep secrets
- They rely on redirect URI validation instead

### What If Someone Extracts the Client ID?

**Client ID is considered public information:**
- It's okay if someone knows your Client ID
- It's registered with AniList and tied to your redirect URI
- Without the redirect URI, they can't complete the OAuth flow
- Users still must authorize the app

**Client Secret is different:**
- If exposed, it could be used to impersonate your app
- But in a native app, it WILL be exposed
- So using it provides no benefit

### Additional Security Measures

Instead of relying on client secret, AniLedger uses:

1. **Keychain Storage**
   - Access tokens stored in macOS Keychain
   - Encrypted by the operating system
   - Protected by user's login credentials

2. **HTTPS Only**
   - All API requests use HTTPS
   - Prevents man-in-the-middle attacks
   - Tokens encrypted in transit

3. **Token Expiration**
   - Tokens expire and must be refreshed
   - Limits damage if token is compromised
   - User can revoke access anytime

4. **Redirect URI Validation**
   - Custom URI scheme: `aniledger://auth-callback`
   - Only AniLedger can handle this scheme
   - Prevents authorization code interception

## Conclusion

**AniLedger correctly implements OAuth 2.0 for native applications by:**
- ✅ Using only the Client ID
- ✅ NOT using the Client Secret
- ✅ Relying on redirect URI validation
- ✅ Following RFC 8252 best practices
- ✅ Being honest about native app limitations

**Using a client secret in a native app would:**
- ❌ Provide no additional security
- ❌ Create a false sense of security
- ❌ Violate OAuth 2.0 best practices
- ❌ Make the codebase harder to open-source
- ❌ Require secret rotation on every compromise

## References

- [RFC 8252: OAuth 2.0 for Native Apps](https://datatracker.ietf.org/doc/html/rfc8252)
- [OAuth 2.0 Security Best Practices](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [AniList API Documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)

## Questions?

**Q: But AniList gives me a client secret, shouldn't I use it?**
A: No. Just because it's provided doesn't mean it's appropriate for native apps. It's there for server-side applications.

**Q: Won't my app be less secure without it?**
A: No. Using it in a native app provides zero additional security since it can be extracted.

**Q: What if someone steals my Client ID?**
A: That's okay - Client ID is public. They still can't complete OAuth without your redirect URI.

**Q: Should I keep my Client ID secret anyway?**
A: It's good practice for privacy (not security), but it's not critical like a client secret would be.

**Q: Can I add PKCE for extra security?**
A: Yes! PKCE (Proof Key for Code Exchange) is a great addition for native apps. It's on the roadmap for future enhancement.

---

**Remember:** In native apps, there are no secrets - only public clients. Design accordingly! 🔒
