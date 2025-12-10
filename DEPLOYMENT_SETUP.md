# Deployment Setup Guide

This guide explains how to set up credentials for automated iOS App Store deployment via GitHub Actions.

## Required Credentials

You need to set up the following GitHub Secrets in your repository:

### Option 1: App Store Connect API Key (Recommended)

**Why:** More secure, no 2FA needed, better for CI/CD

**Steps:**

1. **Create API Key:**
   - Go to https://appstoreconnect.apple.com/
   - Navigate to **Users and Access** → **Keys** tab
   - Click **+** to create a new key
   - Name it (e.g., "GitHub Actions")
   - Set access level to **App Manager** or **Admin**
   - Click **Generate**
   - **Download the `.p8` file** (you can only download it once!)
   - Note the **Key ID** and **Issuer ID** shown on screen

2. **Get Your Team ID:**
   - Go to https://developer.apple.com/account/
   - Your Team ID is shown at the top right (e.g., "Team: ABC123DEFG")
   - Or go to **Membership** → Your Team ID is listed there

3. **Add GitHub Secrets:**
   - Go to your repository → **Settings** → **Secrets and variables** → **Actions**
   - Add these secrets:
     - `APP_STORE_CONNECT_API_KEY_ID` - The Key ID from step 1
     - `APP_STORE_CONNECT_ISSUER_ID` - The Issuer ID from step 1
     - `APP_STORE_CONNECT_API_KEY_CONTENT` - The entire contents of the `.p8` file
     - `FASTLANE_TEAM_ID` - Your Apple Developer Team ID (optional but recommended for automatic code signing)

### Option 2: Apple ID + App-Specific Password (Alternative)

**Why:** Simpler setup, but requires 2FA and is less secure

**Steps:**

1. **Enable 2FA on Apple ID** (if not already enabled)

2. **Create App-Specific Password:**
   - Go to https://appleid.apple.com/
   - Sign in → **Sign-In and Security** → **App-Specific Passwords**
   - Click **Generate an app-specific password**
   - Name it (e.g., "GitHub Actions")
   - Copy the generated password

3. **Add GitHub Secrets:**
   - `FASTLANE_USER` - Your Apple ID email
   - `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` - The app-specific password from step 2

### Code Signing Certificate (Required)

**Steps:**

1. **Export Certificate from Keychain:**
   - Open **Keychain Access** on your Mac
   - Find your **Apple Distribution** certificate
   - Right-click → **Export** → Save as `.p12` file
   - Set a password when prompted

2. **Convert to Base64:**
   ```bash
   base64 -i YourCertificate.p12 | pbcopy
   ```

3. **Add GitHub Secrets:**
   - `APPLE_CERTIFICATE_BASE64` - The base64-encoded certificate (from step 2)
   - `APPLE_CERTIFICATE_PASSWORD` - The password you set when exporting
   - `KEYCHAIN_PASSWORD` - A temporary password for the CI keychain (e.g., "temp123")

## Quick Setup Checklist

- [ ] Created App Store Connect API Key (Option 1) OR App-Specific Password (Option 2)
- [ ] Exported code signing certificate as `.p12`
- [ ] Converted certificate to base64
- [ ] Added all required secrets to GitHub repository

## Testing

After setting up secrets, the workflow will automatically:
- Build your app when `.VERSION` is incremented on `main`
- Upload to TestFlight if version check passes
- Sign the app with your certificate

## Troubleshooting

**"No API key found" error:**
- Verify all three API key secrets are set correctly
- Check that the `.p8` file content is correct (should start with `-----BEGIN PRIVATE KEY-----`)

**"Invalid credentials" error:**
- Verify Apple ID and app-specific password are correct
- Ensure 2FA is enabled on your Apple ID

**"Code signing failed" error:**
- Verify certificate is correctly base64 encoded
- Check certificate password is correct
- Ensure certificate hasn't expired

## Local Development Setup

For running Fastlane commands locally (outside of CI/CD), you need to set up environment variables.

### Quick Setup

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` and add your credentials:**
   - `APP_STORE_CONNECT_API_KEY_ID` - Your API key ID
   - `APP_STORE_CONNECT_ISSUER_ID` - Your issuer ID
   - `APP_STORE_CONNECT_API_KEY_CONTENT` - Full contents of your `.p8` file (including BEGIN/END lines)
   - `OPENAI_API_KEY` - Optional, for AI-generated release notes

3. **Source the setup script before running Fastlane:**
   ```bash
   source scripts/setup_local_env.sh
   bundle exec fastlane release
   ```

### Alternative: Manual Environment Variables

If you prefer not to use a `.env` file, you can export variables manually:

```bash
export APP_STORE_CONNECT_API_KEY_ID="your_key_id"
export APP_STORE_CONNECT_ISSUER_ID="your_issuer_id"
export APP_STORE_CONNECT_API_KEY_CONTENT="$(cat /path/to/AuthKey_XXX.p8)"
export OPENAI_API_KEY="your_openai_key"  # Optional
```

### Using Apple ID Instead (Not Recommended)

If you don't set up the API key, Fastlane will prompt for Apple ID credentials interactively. This requires:
- Your Apple ID password
- 2FA code entry
- Less secure and not suitable for CI/CD

**Note:** The `.env` file is gitignored and will never be committed to the repository.

## References

- [App Store Connect API Documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)

