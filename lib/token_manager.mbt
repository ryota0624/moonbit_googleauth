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
}

///|
/// Create a new TokenManager instance
pub fn new_token_manager(
  access_token : String,
  expires_in : Int,
  token_type : String,
) -> TokenManager {
  { access_token, expires_in, issued_at_offset: 0, token_type }
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
/// Get remaining seconds until token expires
///
/// Returns negative value if already expired
pub fn TokenManager::remaining_seconds(
  self : TokenManager,
  current_time_offset : Int,
) -> Int {
  self.issued_at_offset + self.expires_in - current_time_offset
}
