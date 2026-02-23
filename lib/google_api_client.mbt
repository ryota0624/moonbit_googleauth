///|
/// High-level Google API Client
///
/// Provides automatic token refresh and authentication management.
/// Implements functional update pattern consistent with MoonBit idioms.

///|
/// Google API Client with token management
pub struct GoogleApiClient {
  auth_client : GoogleAuthClient
  token_manager : TokenManager?
}

///|
/// Create a new Google API Client instance
///
/// Client starts in unauthenticated state. Call authenticate() to obtain a token.
pub fn new_api_client(auth_client : GoogleAuthClient) -> GoogleApiClient {
  { auth_client, token_manager: None }
}

///|
/// Create a Google API Client with a token (for testing)
pub fn new_api_client_with_token(
  auth_client : GoogleAuthClient,
  token_manager : TokenManager,
) -> GoogleApiClient {
  { auth_client, token_manager: Some(token_manager) }
}

///|
/// Check if client is authenticated (has valid token)
pub fn GoogleApiClient::is_authenticated(self : GoogleApiClient) -> Bool {
  match self.token_manager {
    Some(_) => true
    None => false
  }
}

///|
/// Authenticate and obtain a token
///
/// Calls the underlying auth_client to get an access token and creates
/// a TokenManager to track its lifecycle.
///
/// Returns:
/// - Ok(GoogleApiClient): Updated client with token
/// - Err(AuthenticationError): If token retrieval fails
pub fn GoogleApiClient::authenticate(
  self : GoogleApiClient,
) -> Result[GoogleApiClient, AuthenticationError] {
  match get_access_token(self.auth_client) {
    Ok(token) => {
      // Assume 3600 seconds (1 hour) default expiry for now
      // Phase 3 will extract this from response metadata
      let manager = new_token_manager(token, 3600, "Bearer")
      Ok({ auth_client: self.auth_client, token_manager: Some(manager) })
    }
    Err(err) => Err(err)
  }
}

///|
/// Get a valid token (must not be expired)
///
/// Parameters:
/// - `current_time_offset`: Current time offset in seconds
///
/// Returns:
/// - Ok(token): Valid access token string
/// - Err(AuthenticationError): If not authenticated or token expired
pub fn GoogleApiClient::get_valid_token(
  self : GoogleApiClient,
  current_time_offset : Int,
) -> Result[String, AuthenticationError] {
  match self.token_manager {
    Some(manager) =>
      if manager.is_expired(current_time_offset) {
        Err(InvalidCredentials("Token has expired"))
      } else {
        Ok(manager.get_token())
      }
    None => Err(InvalidCredentials("Not authenticated"))
  }
}

///|
/// Refresh token if needed (within 5 minutes of expiry)
///
/// Parameters:
/// - `current_time_offset`: Current time offset in seconds
///
/// Returns:
/// - Ok(GoogleApiClient): Updated client (may be same if refresh not needed)
/// - Err(AuthenticationError): If refresh fails
pub fn GoogleApiClient::refresh_token_if_needed(
  self : GoogleApiClient,
  current_time_offset : Int,
) -> Result[GoogleApiClient, AuthenticationError] {
  match self.token_manager {
    Some(manager) =>
      if manager.needs_refresh(current_time_offset) {
        // Token needs refresh, authenticate again
        self.authenticate()
      } else {
        // Token still valid
        Ok(self)
      }
    None =>
      // Not yet authenticated, attempt authentication
      self.authenticate()
  }
}
