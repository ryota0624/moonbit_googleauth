# MoonBit Google OAuth2 Library

A lightweight, idiomatic MoonBit library for Google OAuth2 authentication, built on top of the `ryota0624/oauth2` library.

## Features

- **OAuth2 Authorization Code Flow**: Full PKCE support for secure authorization
- **Service Account Authentication**: Application Default Credentials (ADC) support
- **Token Lifecycle Management**: Automatic token expiration tracking and refresh
- **Token Storage**: In-memory and file-based token persistence
- **Metadata Server Integration**: Support for GCP environment authentication (GCE, GKE, Cloud Run)
- **High-Level API**: Easy-to-use client for token management and refresh

## Installation

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "ryota0624/googleauth": "0.1.0",
    "ryota0624/oauth2": "0.1.2",
    "mizchi/x": "0.1.3"
  }
}
```

## Quick Start

### OAuth2 Authorization Code Flow

```moonbit
pub fn main() {
  // Create OAuth2 client with PKCE support
  let client = GoogleOAuth2Client::{
    client_id: "your-client-id",
    client_secret: "your-client-secret",
    redirect_uri: "http://localhost:3000/callback",
    auth_uri: GOOGLE_AUTH_ENDPOINT,
    token_uri: GOOGLE_TOKEN_ENDPOINT,
    scopes: ["openid", "email", "profile"],
    pkce_verifier: None,
  }

  // Build authorization URL
  let auth_url = client.build_auth_url()
  println("Visit: " + auth_url)

  // After user grants permission, verify callback
  match client.verify_callback("code=...&state=...") {
    Ok(_) => println("Authorization successful")
    Err(err) => println("Authorization failed")
  }
}
```

### Service Account Authentication (ADC)

```moonbit
async fn main() {
  // Automatically detect authentication method (ADC → Metadata Server)
  match auto_detect_and_authenticate() {
    Ok(auth_client) => {
      let api_client = new_api_client(auth_client)
      match api_client.refresh_token_if_needed(0) {
        Ok(client) => {
          match client.get_valid_token(0) {
            Ok(token) => println("Token: " + token)
            Err(_) => println("Failed to get token")
          }
        }
        Err(_) => println("Failed to authenticate")
      }
    }
    Err(_) => println("No authentication method available")
  }
}
```

## Core Components

1. **GoogleOAuth2Client** - OAuth2 authorization with PKCE
2. **GoogleAuthClient** - Multi-method authentication with auto-detection
3. **TokenManager** - Token lifecycle (expiration, refresh)
4. **GoogleApiClient** - High-level API with automatic refresh
5. **TokenStorage** - In-memory and file-based persistence

## Authentication Methods

Auto-detection order:
1. Application Default Credentials (ADC) - Service account JSON key
2. Metadata Server - GCP environment (GCE, GKE, Cloud Run)

## Supported Scopes

```moonbit
basic_scopes()    // openid, email, profile
drive_scopes()    // Google Drive
gmail_scopes()    // Gmail
calendar_scopes() // Google Calendar
docs_scopes()     // Google Docs
sheets_scopes()   // Google Sheets
```

## Documentation

- [**Quickstart Guide**](docs/quickstart.md) - Step-by-step examples
- [**API Reference**](docs/api_reference.md) - Complete API documentation
- [**Google Setup**](docs/google_setup.md) - Google Cloud Console setup

## Testing

```bash
moon test    # 80+ tests
moon fmt lib # Format code
```

## Roadmap

- ✅ OAuth2 Authorization Code Flow
- ✅ Service Account ADC
- ✅ Token Lifecycle Management
- ✅ Token Storage & Persistence
- ✅ Async File I/O Integration
- 🔄 Unix Timestamp Support (Phase 4)
- 📋 Client Credentials Flow (Phase 5)
- 📋 Metadata Server Token Retrieval (Phase 5)

## License

Apache-2.0
