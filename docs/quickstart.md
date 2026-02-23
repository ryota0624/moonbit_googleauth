# Quickstart Guide

Get started with MoonBit Google OAuth2 authentication in 5 minutes.

## Prerequisites

- MoonBit installed
- Google OAuth2 credentials (see [Google Setup Guide](google_setup.md))

## 1. Setup Your MoonBit Project

Add dependencies to `moon.mod.json`:

```json
{
  "deps": {
    "ryota0624/googleauth": "0.1.0",
    "ryota0624/oauth2": "0.1.2",
    "mizchi/x": "0.1.3"
  }
}
```

Update `lib/moon.pkg`:

```json
import {
  "ryota0624/googleauth",
  "ryota0624/oauth2",
  "mizchi/x/fs",
  "mizchi/x/sys",
  "moonbitlang/core/json"
}
```

## 2. OAuth2 Authorization Flow (User Login)

For web applications where users grant permission:

```moonbit
fn build_login_url() -> String {
  let client = GoogleOAuth2Client::{
    client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com",
    client_secret: "YOUR_CLIENT_SECRET",
    redirect_uri: "http://localhost:3000/callback",
    auth_uri: GOOGLE_AUTH_ENDPOINT,
    token_uri: GOOGLE_TOKEN_ENDPOINT,
    scopes: ["openid", "email", "profile"],
    pkce_verifier: None,
  }

  client.build_auth_url()
}

fn handle_callback(callback_url: String) -> Result[String, String] {
  let client = GoogleOAuth2Client::{
    client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com",
    client_secret: "YOUR_CLIENT_SECRET",
    redirect_uri: "http://localhost:3000/callback",
    auth_uri: GOOGLE_AUTH_ENDPOINT,
    token_uri: GOOGLE_TOKEN_ENDPOINT,
    scopes: ["openid", "email", "profile"],
    pkce_verifier: None,
  }

  match client.verify_callback(callback_url) {
    Ok(client_with_code) => {
      // Authorization code is now in client_with_code
      // Exchange with your backend for tokens
      Ok("Authorization successful")
    }
    Err(err) => Err("Authorization failed")
  }
}
```

## 3. Service Account Authentication (Server-to-Server)

For backend services using a service account JSON key:

### Using Application Default Credentials (ADC)

ADC automatically detects credentials from environment. This is the recommended approach:

```moonbit
async fn authenticate_with_adc() -> Result[GoogleApiClient, AuthenticationError] {
  // Automatically tries:
  // 1. GOOGLE_APPLICATION_CREDENTIALS environment variable
  // 2. Metadata Server (if running on GCP)
  match auto_detect_and_authenticate() {
    Ok(auth_client) => {
      let api_client = new_api_client(auth_client)
      Ok(api_client)
    }
    Err(err) => Err(err)
  }
}
```

### Setting up ADC

**Option 1: Environment Variable (Recommended)**

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

**Option 2: GCP Environment**

If running on Google Cloud, metadata server is automatically used:
- Google Compute Engine (GCE)
- Google Kubernetes Engine (GKE)
- Cloud Run
- Cloud Functions

## 4. Getting and Refreshing Tokens

Once authenticated, manage tokens automatically:

```moonbit
async fn use_authenticated_client() -> Result[String, AuthenticationError] {
  // Get authenticated client
  match auto_detect_and_authenticate() {
    Ok(auth_client) => {
      let mut client = new_api_client(auth_client)

      // Automatically refresh if within 5 minutes of expiry
      match client.refresh_token_if_needed(0) {
        Ok(refreshed_client) => {
          client = refreshed_client

          // Get current valid token
          match client.get_valid_token(0) {
            Ok(token) => {
              // Use token in API requests
              println("Token: " + token)
              Ok(token)
            }
            Err(err) => Err(err)
          }
        }
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}
```

## 5. Token Storage and Persistence

Save tokens to file for reuse across restarts:

```moonbit
async fn save_and_load_token(
  client: GoogleApiClient,
  storage_path: String
) -> Result[GoogleApiClient, AuthenticationError] {
  let storage = new_file_storage(storage_path)

  // Save current token
  match client.token_manager {
    Some(manager) => {
      match storage.save(manager) {
        Ok(_) => println("Token saved")
        Err(_) => println("Failed to save token")
      }
    }
    None => println("No token to save")
  }

  // Load token later
  match storage.load() {
    Ok(loaded_manager) => {
      let restored_client = new_api_client_with_token(
        client.auth_client,
        loaded_manager
      )
      Ok(restored_client)
    }
    Err(_) => Err(InvalidCredentials("No saved token"))
  }
}
```

## 6. Error Handling

All functions return `Result` for robust error handling:

```moonbit
match auto_detect_and_authenticate() {
  Ok(client) => {
    println("Authentication successful")
    // Use client
  }
  Err(InvalidCredentials(msg)) => {
    println("Invalid credentials: " + msg)
  }
  Err(NoValidCredentials) => {
    println("No credentials found in environment")
  }
  Err(MetadataServerError(msg)) => {
    println("Metadata server error: " + msg)
  }
}
```

## 7. Common Scope Examples

```moonbit
// For Google Drive access
let drive_client = GoogleOAuth2Client::{
  // ... base config ...
  scopes: drive_scopes(),
  // ... rest of config ...
}

// For Gmail access
let gmail_client = GoogleOAuth2Client::{
  // ... base config ...
  scopes: gmail_scopes(),
  // ... rest of config ...
}

// Multiple scopes
let multi_client = GoogleOAuth2Client::{
  // ... base config ...
  scopes: [
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/calendar",
  ],
  // ... rest of config ...
}
```

## Next Steps

- Check [API Reference](api_reference.md) for detailed function signatures
- See [Google Setup Guide](google_setup.md) for OAuth2 credential configuration
- View example code in `examples/` directory

## Common Issues

**"No credentials found"**
- Ensure `GOOGLE_APPLICATION_CREDENTIALS` environment variable is set
- Verify the JSON key file path is correct
- Check that you're running on a GCP environment (for Metadata Server)

**"Token expired"**
- Ensure you're calling `refresh_token_if_needed()` before using token
- The client automatically detects 5-minute expiry window

**"Invalid credentials"**
- Verify service account JSON key is valid (see [Google Setup](google_setup.md))
- Check required fields in JSON: `type`, `project_id`, `private_key_id`, `private_key`, `client_email`, `client_id`, `auth_uri`, `token_uri`

---

**Need more help?** Check [API Reference](api_reference.md) or [Google Setup Guide](google_setup.md).
