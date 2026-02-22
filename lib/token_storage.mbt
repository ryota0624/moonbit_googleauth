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
  self : InMemoryTokenStorage,
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
/// Save token to file storage (stub - Phase 3)
///
/// Note: Full implementation requires file I/O and async support.
/// Currently returns error to maintain API compatibility.
pub fn FileTokenStorage::save(
  _self : FileTokenStorage,
  _token : TokenManager,
) -> Result[Unit, TokenStorageError] {
  Err(
    TokenStorageError::StorageNotAvailable(
      "File storage not available in Phase 2. Use InMemoryTokenStorage instead.",
    ),
  )
}

///|
/// Load token from file storage (stub - Phase 3)
///
/// Note: Full implementation requires file I/O and async support.
/// Currently returns error to maintain API compatibility.
pub fn FileTokenStorage::load(
  _self : FileTokenStorage,
) -> Result[TokenManager, TokenStorageError] {
  Err(
    TokenStorageError::StorageNotAvailable(
      "File storage not available in Phase 2. Use InMemoryTokenStorage instead.",
    ),
  )
}

///|
/// Clear token from file storage (stub - Phase 3)
///
/// Note: Full implementation requires file I/O and async support.
/// Currently returns error to maintain API compatibility.
pub fn FileTokenStorage::clear(
  _self : FileTokenStorage,
) -> Result[Unit, TokenStorageError] {
  Err(
    TokenStorageError::StorageNotAvailable(
      "File storage not available in Phase 2. Use InMemoryTokenStorage instead.",
    ),
  )
}
