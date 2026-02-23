# API Reference

Complete API documentation for the MoonBit Google OAuth2 library.

## Table of Contents

1. [Google Constants](#google-constants)
2. [GoogleOAuth2Client](#googleoauth2client)
3. [GoogleAuthClient](#googleauthclient)
4. [GoogleApiClient](#googleapiclient)
5. [TokenManager](#tokenmanager)
6. [TokenStorage](#tokenstorage)
7. [Error Types](#error-types)
8. [Service Account Types](#service-account-types)

---

## Google Constants

### Endpoints

```moonbit
pub fn GOOGLE_AUTH_ENDPOINT() -> String
// Returns: "https://accounts.google.com/o/oauth2/v2/auth"

pub fn GOOGLE_TOKEN_ENDPOINT() -> String
// Returns: "https://oauth2.googleapis.com/token"

pub fn GOOGLE_REVOKE_ENDPOINT() -> String
// Returns: "https://oauth2.googleapis.com/revoke"

pub fn GOOGLE_USERINFO_ENDPOINT() -> String
// Returns: "https://www.googleapis.com/oauth2/v2/userinfo"
```

### Scope Functions

```moonbit
pub fn basic_scopes() -> Array[String]
// Returns: ["openid", "email", "profile"]

pub fn drive_scopes() -> Array[String]
// Returns: ["https://www.googleapis.com/auth/drive"]

pub fn gmail_scopes() -> Array[String]
// Returns: ["https://www.googleapis.com/auth/gmail"]

pub fn calendar_scopes() -> Array[String]
// Returns: ["https://www.googleapis.com/auth/calendar"]

pub fn docs_scopes() -> Array[String]
// Returns: ["https://www.googleapis.com/auth/docs"]

pub fn sheets_scopes() -> Array[String]
// Returns: ["https://www.googleapis.com/auth/sheets"]
```

---

## GoogleOAuth2Client

OAuth2 authorization code flow client with PKCE support.

### Structure

```moonbit
pub struct GoogleOAuth2Client {
  client_id: String
  client_secret: String
  redirect_uri: String
  auth_uri: String
  token_uri: String
  scopes: Array[String]
  pkce_verifier: String?
}
```

### Methods

#### `GoogleOAuth2Client::build_auth_url()`

Generates authorization URL for user to visit.

```moonbit
pub fn GoogleOAuth2Client::build_auth_url(
  self: GoogleOAuth2Client
) -> String
```

**Returns:** Authorization URL with PKCE challenge

**Example:**
```moonbit
let url = client.build_auth_url()
// URL format: https://accounts.google.com/o/oauth2/v2/auth?
//   client_id=...&redirect_uri=...&scope=...&code_challenge=...
```

#### `GoogleOAuth2Client::verify_callback()`

Verifies authorization callback and returns client with authorization code.

```moonbit
pub fn GoogleOAuth2Client::verify_callback(
  self: GoogleOAuth2Client,
  callback_url: String
) -> Result[GoogleOAuth2Client, String]
```

**Parameters:**
- `callback_url`: Full redirect URL with `code` and `state` parameters

**Returns:**
- `Ok(client)`: Client ready for token exchange
- `Err(msg)`: Error description

---

## GoogleAuthClient

Multi-method authentication with automatic detection.

### Structure

```moonbit
pub struct GoogleAuthClient {
  auth_type: AuthCredentialsType
  credentials: ServiceAccountCredentials?
}
```

### Methods

#### `new_auth_client()`

Creates auth client with optional service account credentials.

```moonbit
pub fn new_auth_client(
  credentials: ServiceAccountCredentials?
) -> GoogleAuthClient
```

#### `auto_detect_and_authenticate()`

Automatically detects and uses best available authentication method.

```moonbit
pub async fn auto_detect_and_authenticate(
) -> Result[GoogleAuthClient, AuthenticationError]
```

**Detection Order:**
1. Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS env var)
2. Metadata Server (if running on GCP)

**Returns:**
- `Ok(client)`: Authenticated client
- `Err(err)`: Authentication error

#### `get_access_token()`

Gets access token using configured authentication method.

```moonbit
pub async fn get_access_token(
  client: GoogleAuthClient
) -> Result[String, AuthenticationError]
```

**Returns:**
- `Ok(token)`: Access token string
- `Err(err)`: Error getting token

---

## GoogleApiClient

High-level API client with automatic token management.

### Structure

```moonbit
pub struct GoogleApiClient {
  auth_client: GoogleAuthClient
  token_manager: TokenManager?
}
```

### Methods

#### `new_api_client()`

Creates API client from authentication client.

```moonbit
pub fn new_api_client(
  auth_client: GoogleAuthClient
) -> GoogleApiClient
```

#### `new_api_client_with_token()`

Creates API client with pre-existing token (for testing).

```moonbit
pub fn new_api_client_with_token(
  auth_client: GoogleAuthClient,
  token_manager: TokenManager
) -> GoogleApiClient
```

#### `GoogleApiClient::is_authenticated()`

Checks if client has valid authentication.

```moonbit
pub fn GoogleApiClient::is_authenticated(
  self: GoogleApiClient
) -> Bool
```

#### `GoogleApiClient::authenticate()`

Obtains access token from authentication client.

```moonbit
pub async fn GoogleApiClient::authenticate(
  self: GoogleApiClient
) -> Result[GoogleApiClient, AuthenticationError]
```

**Returns:** Updated client with token, or error

#### `GoogleApiClient::get_valid_token()`

Gets current valid access token.

```moonbit
pub fn GoogleApiClient::get_valid_token(
  self: GoogleApiClient,
  current_time_offset: Int
) -> Result[String, AuthenticationError]
```

**Parameters:**
- `current_time_offset`: Current time in seconds (relative offset)

**Returns:**
- `Ok(token)`: Valid access token
- `Err(InvalidCredentials)`: Token expired or not authenticated

#### `GoogleApiClient::refresh_token_if_needed()`

Automatically refreshes token if near expiry (5-minute buffer).

```moonbit
pub async fn GoogleApiClient::refresh_token_if_needed(
  self: GoogleApiClient,
  current_time_offset: Int
) -> Result[GoogleApiClient, AuthenticationError]
```

**Returns:** Updated client (may be same if refresh not needed)

---

## TokenManager

Manages token lifecycle and expiration.

### Structure

```moonbit
pub struct TokenManager {
  access_token: String
  expires_in: Int         // Seconds until expiry
  issued_at_offset: Int   // Offset when token was issued
  token_type: String      // Typically "Bearer"
}
```

### Methods

#### `new_token_manager()`

Creates token manager.

```moonbit
pub fn new_token_manager(
  access_token: String,
  expires_in: Int,
  token_type: String
) -> TokenManager
```

#### `TokenManager::is_expired()`

Checks if token has expired.

```moonbit
pub fn TokenManager::is_expired(
  self: TokenManager,
  current_time_offset: Int
) -> Bool
```

#### `TokenManager::needs_refresh()`

Checks if token should be refreshed (5-minute buffer).

```moonbit
pub fn TokenManager::needs_refresh(
  self: TokenManager,
  current_time_offset: Int
) -> Bool
```

Refreshes when within 5 minutes of expiry.

#### `TokenManager::remaining_seconds()`

Calculates seconds until token expiry.

```moonbit
pub fn TokenManager::remaining_seconds(
  self: TokenManager,
  current_time_offset: Int
) -> Int
```

#### `TokenManager::get_token()`

Gets access token string.

```moonbit
pub fn TokenManager::get_token(
  self: TokenManager
) -> String
```

---

## TokenStorage

Pluggable token persistence interface.

### InMemoryTokenStorage

```moonbit
pub fn new_in_memory_storage() -> InMemoryTokenStorage

pub fn InMemoryTokenStorage::save(
  self: InMemoryTokenStorage,
  token: TokenManager
) -> InMemoryTokenStorage

pub fn InMemoryTokenStorage::load(
  self: InMemoryTokenStorage
) -> Result[TokenManager, TokenStorageError]

pub fn InMemoryTokenStorage::clear(
  self: InMemoryTokenStorage
) -> InMemoryTokenStorage
```

### FileTokenStorage

```moonbit
pub fn new_file_storage(file_path: String) -> FileTokenStorage

pub async fn FileTokenStorage::save(
  self: FileTokenStorage,
  token: TokenManager
) -> Result[Unit, TokenStorageError]

pub async fn FileTokenStorage::load(
  self: FileTokenStorage
) -> Result[TokenManager, TokenStorageError]

pub async fn FileTokenStorage::clear(
  self: FileTokenStorage
) -> Result[Unit, TokenStorageError]
```

**File Format:** JSON
```json
{
  "access_token": "ya29.a0AfH6SMB...",
  "expires_in": 3600,
  "issued_at_offset": 1234567890,
  "token_type": "Bearer"
}
```

---

## Error Types

### AuthenticationError

```moonbit
pub enum AuthenticationError {
  InvalidCredentials(String)
  NoValidCredentials
  MetadataServerError(String)
}
```

### TokenStorageError

```moonbit
pub enum TokenStorageError {
  NotFound
  StorageNotAvailable(String)
  DeserializationError(String)
}
```

### AdcError

```moonbit
pub enum AdcError {
  IoCCError(String)
  EnvironmentVariableNotSet
  JsonParseError(String)
  MissingRequiredField(String)
  InvalidJsonFormat(String)
}
```

### MetadataError

```moonbit
pub enum MetadataError {
  MetadataServerUnavailable
  InvalidResponse(String)
  HttpError(Int, String)
  Timeout
  ParsingError(String)
}
```

---

## Service Account Types

### ServiceAccountCredentials

```moonbit
pub struct ServiceAccountCredentials {
  service_account_type: String     // "service_account"
  project_id: String
  private_key_id: String
  private_key: String              // PEM-encoded private key
  client_email: String
  client_id: String
  auth_uri: String
  token_uri: String
  auth_provider_x509_cert_url: String?
  client_x509_cert_url: String?
}
```

### Functions

#### `parse_service_account_key()`

Parses service account JSON key.

```moonbit
pub fn parse_service_account_key(
  json_str: String
) -> Result[ServiceAccountCredentials, AdcError]
```

#### `validate_credentials()`

Validates service account credentials.

```moonbit
pub fn validate_credentials(
  creds: ServiceAccountCredentials
) -> Result[Unit, AdcError]
```

#### `load_credentials_from_env()`

Loads service account key from environment variable.

```moonbit
pub async fn load_credentials_from_env(
) -> Result[ServiceAccountCredentials, AdcError]
```

Uses `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

#### `load_credentials_from_file()`

Loads service account key from file.

```moonbit
pub async fn load_credentials_from_file(
  file_path: String
) -> Result[ServiceAccountCredentials, AdcError]
```

---

## Usage Patterns

### Pattern 1: Simple Authentication

```moonbit
async fn get_token() -> Result[String, AuthenticationError] {
  match auto_detect_and_authenticate() {
    Ok(auth_client) => get_access_token(auth_client)
    Err(err) => Err(err)
  }
}
```

### Pattern 2: Token Refresh

```moonbit
async fn ensure_valid_token(mut client: GoogleApiClient) -> Result[GoogleApiClient, AuthenticationError] {
  match client.refresh_token_if_needed(0) {
    Ok(refreshed) => Ok(refreshed)
    Err(err) => Err(err)
  }
}
```

### Pattern 3: Token Persistence

```moonbit
async fn save_token(client: GoogleApiClient, path: String) -> Result[Unit, TokenStorageError] {
  let storage = new_file_storage(path)
  match client.token_manager {
    Some(manager) => storage.save(manager)
    None => Err(TokenStorageError::NotFound)
  }
}
```

---

For more examples, see [Quickstart Guide](quickstart.md).
