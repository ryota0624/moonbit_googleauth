///|
/// Token Storage Abstraction
///
/// Defines pluggable storage implementations for persisting TokenManager instances.
/// Phase 2 provides InMemory storage; File storage is stubbed for Phase 3.

///|
/// In-memory token storage using mutable cell
///
/// Simple reference-based storage for development and testing.
/// Not persistent across process restarts.
pub struct InMemoryTokenStorage {
  token : TokenManager?
}

///|
/// Create a new in-memory token storage instance
pub fn new_in_memory_storage() -> InMemoryTokenStorage {
  { token: None }
}

///|
/// Save token to in-memory storage, returning updated storage
pub fn InMemoryTokenStorage::save(
  _self : InMemoryTokenStorage,
  token : TokenManager,
) -> InMemoryTokenStorage {
  { token: Some(token) }
}

///|
/// Load token from in-memory storage
pub fn InMemoryTokenStorage::load(
  self : InMemoryTokenStorage,
) -> Result[TokenManager, TokenStorageError] {
  match self.token {
    Some(token) => Ok(token)
    None => Err(TokenStorageError::NotFound)
  }
}

///|
/// Clear token from in-memory storage, returning cleared storage
pub fn InMemoryTokenStorage::clear(
  _self : InMemoryTokenStorage,
) -> InMemoryTokenStorage {
  { token: None }
}

///|
/// File-based token storage (stub implementation)
///
/// Phase 2 placeholder. Full implementation in Phase 3.
/// File I/O capabilities depend on MoonBit runtime environment.
pub struct FileTokenStorage {
  file_path : String
}

///|
/// Create a new file-based token storage instance
pub fn new_file_storage(file_path : String) -> FileTokenStorage {
  { file_path, }
}

///|
/// Save token to file storage
///
/// Persists token information as JSON to the specified file path.
pub fn FileTokenStorage::save(
  self : FileTokenStorage,
  token : TokenManager,
) -> Result[Unit, TokenStorageError] {
  let json = "{\"access_token\":\"" +
    token.access_token +
    "\",\"expires_in\":" +
    token.expires_in.to_string() +
    ",\"issued_at_offset\":" +
    token.issued_at_offset.to_string() +
    ",\"token_type\":\"" +
    token.token_type +
    "\"}"
  try {
    @fs.write_file(self.file_path, json)
    Ok(())
  } catch {
    @fs.IOError(msg) => Err(TokenStorageError::StorageNotAvailable(msg))
  }
}

///|
/// Load token from file storage
///
/// Reads and parses JSON from the file to reconstruct TokenManager.
pub fn FileTokenStorage::load(
  self : FileTokenStorage,
) -> Result[TokenManager, TokenStorageError] {
  let data = @fs.read_file(self.file_path) catch {
    @fs.IOError(_) => return Err(TokenStorageError::NotFound)
  }
  let json_str = data.text() catch {
    _ =>
      return Err(
        TokenStorageError::DeserializationError("Failed to decode file content"),
      )
  }
  let json = @json.parse(json_str) catch {
    _e =>
      return Err(
        TokenStorageError::DeserializationError("Failed to parse JSON"),
      )
  }
  let obj = match json {
    Object(o) => o
    _ =>
      return Err(TokenStorageError::DeserializationError("Not a JSON object"))
  }
  let access_token = match obj.get("access_token") {
    Some(String(s)) => s
    _ =>
      return Err(
        TokenStorageError::DeserializationError("Missing access_token"),
      )
  }
  let expires_in = match obj.get("expires_in") {
    Some(Number(n)) => n.to_int()
    _ =>
      return Err(TokenStorageError::DeserializationError("Missing expires_in"))
  }
  let issued_at_offset = match obj.get("issued_at_offset") {
    Some(Number(n)) => n.to_int()
    _ =>
      return Err(
        TokenStorageError::DeserializationError("Missing issued_at_offset"),
      )
  }
  let token_type = match obj.get("token_type") {
    Some(String(s)) => s
    _ =>
      return Err(TokenStorageError::DeserializationError("Missing token_type"))
  }
  Ok({ access_token, expires_in, issued_at_offset, token_type })
}

///|
/// Clear token from file storage
///
/// Removes the token by clearing or deleting the file.
pub fn FileTokenStorage::clear(
  self : FileTokenStorage,
) -> Result[Unit, TokenStorageError] {
  if @fs.exists(self.file_path) {
    try {
      @fs.write_file(self.file_path, "")
      Ok(())
    } catch {
      @fs.IOError(msg) => Err(TokenStorageError::StorageNotAvailable(msg))
    }
  } else {
    Ok(())
  }
}
