# Google Setup Guide

Complete guide for setting up Google OAuth2 credentials and service accounts.

## Table of Contents

1. [OAuth2 Authorization Credentials](#oauth2-authorization-credentials)
2. [Service Account Setup](#service-account-setup)
3. [Application Default Credentials (ADC)](#application-default-credentials-adc)
4. [Testing Your Setup](#testing-your-setup)

---

## OAuth2 Authorization Credentials

For applications that need user authentication (e.g., "Sign in with Google").

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project selector at the top
3. Click "NEW PROJECT"
4. Enter project name (e.g., "My MoonBit App")
5. Click "CREATE"

### Step 2: Enable OAuth2 API

1. In the Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google+ API" (or just "Google API")
3. Click the result
4. Click "ENABLE"

Alternatively, enable these specific APIs:
- Google+ API
- People API (if using profile info)
- Google Drive API (if accessing drive)
- Gmail API (if accessing Gmail)

### Step 3: Create OAuth2 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. If prompted, configure the OAuth consent screen first:
   - User type: External (for development)
   - Click "Create"
   - App name: "My MoonBit App"
   - User support email: your@email.com
   - Developer contact: your@email.com
   - Click "Save and Continue"
   - Add scopes you'll need (or skip for now)
   - Click "Save and Continue"
   - Add test users (your own email)
   - Click "Save and Continue"

4. After consent screen, return to Credentials
5. Click "Create Credentials" > "OAuth client ID"
6. Application type: Choose based on your use case:
   - **Web application** - For server-side apps or websites
   - **Desktop application** - For command-line or desktop apps
   - **Mobile application** - For mobile apps

### Step 4: Configure Redirect URI

For web applications:

1. After selecting application type, configure:
   - **Authorized JavaScript origins**: Where your app is hosted
     - Local development: `http://localhost:3000`
     - Production: `https://yourdomain.com`

   - **Authorized redirect URIs**: Where users return after login
     - Local: `http://localhost:3000/callback`
     - Production: `https://yourdomain.com/callback`

2. Click "Create"

### Step 5: Copy Your Credentials

You'll see a dialog with:
- **Client ID**: Copy this
- **Client Secret**: Copy this (keep secret!)

Use these in your MoonBit code:

```moonbit
let client = GoogleOAuth2Client::{
  client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com",
  client_secret: "YOUR_CLIENT_SECRET",
  redirect_uri: "http://localhost:3000/callback",
  // ... rest of config ...
}
```

---

## Service Account Setup

For server-to-server authentication (no user interaction).

### Step 1: Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Go to "APIs & Services" > "Service Accounts"
3. Click "Create Service Account"
4. Service account name: "my-app-service" (or your choice)
5. Service account ID: Auto-filled, keep as is
6. Service account description: Optional
7. Click "Create and Continue"

### Step 2: Grant Permissions

1. Click "Grant this service account access to project" (optional)
2. Select appropriate roles:
   - For testing: "Editor" (full access)
   - For production: Choose specific roles:
     - "Cloud Storage Viewer" (if accessing GCS)
     - "Pub/Sub Editor" (if using Pub/Sub)
     - "BigQuery Job User" (if querying BigQuery)
3. Click "Continue"
4. Click "Done"

### Step 3: Create and Download Key

1. In the Service Accounts list, click on the account you created
2. Go to the "Keys" tab
3. Click "Add Key" > "Create new key"
4. Choose "JSON" (recommended for MoonBit)
5. Click "Create"
6. **Your key file will download automatically** - save it securely
7. Click "Close"

**Important:** This JSON file contains your private key. Keep it secure:
- Never commit to version control
- Never share via email/chat
- Store in a secure location

### Step 4: Understand Your Key File

Your JSON key file contains:

```json
{
  "type": "service_account",
  "project_id": "my-project-123456",
  "private_key_id": "key-id-1234...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "my-app-service@my-project.iam.gserviceaccount.com",
  "client_id": "1234567890",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/my-app-service%40my-project.iam.gserviceaccount.com"
}
```

All fields are required by this library.

---

## Application Default Credentials (ADC)

ADC is the recommended way to authenticate. It automatically detects credentials from your environment.

### Setting Up ADC

#### Option 1: Environment Variable (Recommended)

1. Download your service account JSON key (see [Service Account Setup](#service-account-setup))
2. Set the environment variable:

**macOS/Linux:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

**Windows (PowerShell):**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account-key.json"
```

**Windows (Command Prompt):**
```cmd
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account-key.json
```

3. Your MoonBit app can now use:

```moonbit
async fn main() {
  match auto_detect_and_authenticate() {
    Ok(client) => println("Authenticated!")
    Err(err) => println("Error: " + err)
  }
}
```

#### Option 2: GCP Environment (Google Cloud Hosted)

If running your code on Google Cloud:
- **Google Compute Engine (GCE)**
- **Google Kubernetes Engine (GKE)**
- **Cloud Run**
- **Cloud Functions**

Your code automatically has access via the metadata server. No setup needed:

```moonbit
async fn main() {
  // Works automatically on GCP
  match auto_detect_and_authenticate() {
    Ok(client) => println("Authenticated via metadata server!")
    Err(err) => println("Not on GCP or no permissions")
  }
}
```

### ADC Detection Order

The library tries authentication methods in this order:

1. **Explicit credentials** - If provided directly (Phase 4+)
2. **Environment variable** - `GOOGLE_APPLICATION_CREDENTIALS` points to JSON file
3. **Metadata Server** - If running on GCP
4. **Error** - No method available

---

## Testing Your Setup

### Test OAuth2 Credentials

```moonbit
fn test_oauth2_setup() {
  let client = GoogleOAuth2Client::{
    client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com",
    client_secret: "YOUR_CLIENT_SECRET",
    redirect_uri: "http://localhost:3000/callback",
    auth_uri: GOOGLE_AUTH_ENDPOINT,
    token_uri: GOOGLE_TOKEN_ENDPOINT,
    scopes: ["openid", "email"],
    pkce_verifier: None,
  }

  let url = client.build_auth_url()
  println("Auth URL: " + url)

  // URL should start with:
  // https://accounts.google.com/o/oauth2/v2/auth?...
}
```

### Test Service Account (ADC)

```moonbit
async fn test_service_account_setup() {
  match auto_detect_and_authenticate() {
    Ok(auth_client) => {
      println("✓ ADC detected successfully")

      match get_access_token(auth_client) {
        Ok(token) => {
          println("✓ Got access token")
          println("  Token preview: " + token.substring(0, 20) + "...")
        }
        Err(err) => println("✗ Failed to get token")
      }
    }
    Err(err) => println("✗ ADC setup failed - check GOOGLE_APPLICATION_CREDENTIALS")
  }
}
```

Run with:
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
moon test
```

### Test File-Based Service Account

```moonbit
async fn test_file_credentials() {
  match load_credentials_from_file("/path/to/service-account-key.json") {
    Ok(creds) => {
      println("✓ Loaded credentials from file")
      println("  Project: " + creds.project_id)
      println("  Email: " + creds.client_email)
    }
    Err(err) => println("✗ Failed to load credentials")
  }
}
```

---

## Troubleshooting

### "No credentials found"

**Problem:** `NoValidCredentials` error

**Solutions:**
1. Check `GOOGLE_APPLICATION_CREDENTIALS` is set:
   ```bash
   echo $GOOGLE_APPLICATION_CREDENTIALS
   ```
2. Verify file exists:
   ```bash
   ls -l /path/to/service-account-key.json
   ```
3. Verify you're on GCP or have environment variable set
4. For local development, use environment variable method

### "Invalid credentials"

**Problem:** `InvalidCredentials` error

**Solutions:**
1. Ensure service account JSON has all required fields
2. Check that `private_key_id` and `private_key` are present
3. Verify the JSON file hasn't been corrupted
4. Re-download the key from Google Cloud Console

### "Permission denied"

**Problem:** Authentication succeeds but API calls fail

**Solutions:**
1. Verify service account has necessary IAM roles
2. In Google Cloud Console, go to "IAM & Admin"
3. Find your service account
4. Edit its roles to include required permissions

### "Metadata server unavailable"

**Problem:** Running on GCP but metadata server isn't responding

**Solutions:**
1. Verify you're actually on a GCP resource (GCE, GKE, etc.)
2. Check network connectivity to metadata server
3. For GKE, ensure workload identity is configured
4. Use environment variable as fallback

---

## Best Practices

1. **Never commit credentials** to version control
   - Add to `.gitignore`:
     ```
     service-account-key.json
     .env
     *.pem
     ```

2. **Use least privilege** - Only grant necessary permissions

3. **Rotate keys regularly** - Every 90 days or as needed

4. **Monitor access** - Use Cloud Audit Logs to track API usage

5. **Local vs. Production**:
   - Local: Use environment variable or file-based credentials
   - GCP-hosted: Use metadata server (automatic)
   - CI/CD: Use workload identity or service account keys in secrets

6. **Separate accounts** for different environments:
   - Development: Broad permissions
   - Staging: Limited permissions
   - Production: Minimal necessary permissions

---

Need more help? See [Quickstart Guide](quickstart.md) or [API Reference](api_reference.md).
