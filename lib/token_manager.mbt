///|
/// Token Lifecycle Management
///
/// TokenManager tracks token validity and expiry. Uses offset-based time
/// for compatibility with Phase 2 constraints. Phase 3 will introduce
/// real system timestamps.

///|
/// Token manager for tracking access token validity and expiry
pub struct TokenManager {
  access_token : String
  expires_in : Int
  issued_at_offset : Int
  token_type : String
  issued_at_timestamp : Int? // Unix timestamp (seconds since epoch)
}

///|
/// Token Endpoint Response (Phase 4)
///
/// Represents a response from Google's token endpoint containing
/// access token and optional metadata like expiry time.
pub struct TokenResponse {
  access_token : String
  expires_in : Int // Token lifetime in seconds
  token_type : String // Typically "Bearer"
  scope : String? // Granted scopes (optional)
}

///|
/// Create a TokenResponse (for testing and response parsing)
pub fn new_token_response(
  access_token : String,
  expires_in : Int,
  token_type : String,
  scope : String?,
) -> TokenResponse {
  { access_token, expires_in, token_type, scope }
}

///|
/// Create a new TokenManager instance (offset-based, backward compatible)
pub fn new_token_manager(
  access_token : String,
  expires_in : Int,
  token_type : String,
) -> TokenManager {
  {
    access_token,
    expires_in,
    issued_at_offset: 0,
    token_type,
    issued_at_timestamp: None,
  }
}

///|
/// Create a TokenManager with Unix timestamp
///
/// Parameters:
/// - `access_token`: The access token string
/// - `expires_in`: Time until expiry in seconds
/// - `issued_at_timestamp`: Unix timestamp (seconds since epoch) when token was issued
/// - `token_type`: Token type (typically "Bearer")
pub fn new_token_manager_with_timestamp(
  access_token : String,
  expires_in : Int,
  issued_at_timestamp : Int,
  token_type : String,
) -> TokenManager {
  {
    access_token,
    expires_in,
    issued_at_offset: 0,
    token_type,
    issued_at_timestamp: Some(issued_at_timestamp),
  }
}

///|
/// Check if token has expired based on current time offset
///
/// Token is considered expired when: current_time_offset >= issued_at_offset + expires_in
pub fn TokenManager::is_expired(
  self : TokenManager,
  current_time_offset : Int,
) -> Bool {
  current_time_offset >= self.issued_at_offset + self.expires_in
}

///|
/// Check if token needs refresh (within 5 minutes of expiry)
///
/// Returns true when remaining time < 300 seconds
pub fn TokenManager::needs_refresh(
  self : TokenManager,
  current_time_offset : Int,
) -> Bool {
  let remaining = self.remaining_seconds(current_time_offset)
  remaining < 300 && remaining >= 0
}

///|
/// Get the access token string
pub fn TokenManager::get_token(self : TokenManager) -> String {
  self.access_token
}

///|
/// Get remaining seconds until token expires (offset-based)
///
/// Returns negative value if already expired
pub fn TokenManager::remaining_seconds(
  self : TokenManager,
  current_time_offset : Int,
) -> Int {
  self.issued_at_offset + self.expires_in - current_time_offset
}

///|
/// Check if token has expired based on Unix timestamp
///
/// Token is considered expired when: current_timestamp >= issued_at_timestamp + expires_in
pub fn TokenManager::is_expired_at_timestamp(
  self : TokenManager,
  current_timestamp : Int,
) -> Bool {
  match self.issued_at_timestamp {
    Some(issued_timestamp) =>
      current_timestamp >= issued_timestamp + self.expires_in
    None =>
      // Fallback: if no timestamp available, assume not expired
      // (conservative approach for backward compatibility)
      false
  }
}

///|
/// Check if token needs refresh based on Unix timestamp (within 5 minutes of expiry)
///
/// Returns true when remaining time < 300 seconds
pub fn TokenManager::needs_refresh_at_timestamp(
  self : TokenManager,
  current_timestamp : Int,
) -> Bool {
  let remaining = self.remaining_seconds_at_timestamp(current_timestamp)
  remaining < 300 && remaining >= 0
}

///|
/// Get remaining seconds until token expires (timestamp-based)
///
/// Returns negative value if already expired
pub fn TokenManager::remaining_seconds_at_timestamp(
  self : TokenManager,
  current_timestamp : Int,
) -> Int {
  match self.issued_at_timestamp {
    Some(issued_timestamp) =>
      issued_timestamp + self.expires_in - current_timestamp
    None =>
      // Fallback: if no timestamp available, return large positive number
      // (conservative approach for backward compatibility)
      2147483647 // Max Int32
  }
}

///|
/// Get the timestamp when token was issued (if available)
pub fn TokenManager::get_issued_at_timestamp(self : TokenManager) -> Int? {
  self.issued_at_timestamp
}

///|
/// Get expiry timestamp (if token has timestamp info)
pub fn TokenManager::get_expiry_timestamp(self : TokenManager) -> Int? {
  match self.issued_at_timestamp {
    Some(ts) => Some(ts + self.expires_in)
    None => None
  }
}

///|
/// Create TokenManager from TokenResponse with provided timestamp (Phase 4)
///
/// Utility function to create a TokenManager with actual expires_in from token response.
/// This enables using real expiry times from the token endpoint instead of default values.
///
/// Parameters:
/// - `response`: TokenResponse from token endpoint
/// - `issued_at_timestamp`: Unix timestamp when token was issued
pub fn new_token_manager_from_response(
  response : TokenResponse,
  issued_at_timestamp : Int,
) -> TokenManager {
  {
    access_token: response.access_token,
    expires_in: response.expires_in,
    issued_at_offset: 0,
    token_type: response.token_type,
    issued_at_timestamp: Some(issued_at_timestamp),
  }
}
