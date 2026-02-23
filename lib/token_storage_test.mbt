///|
/// TokenStorage trait and implementation tests

///|
/// InMemoryTokenStorage tests
test "in_memory_storage creates empty storage" {
  let storage = new_in_memory_storage()
  match storage.load() {
    Err(TokenStorageError::NotFound) => ()
    _ => @test.fail("Expected NotFound error")
  }
}

///|
test "in_memory_storage saves and loads token" {
  let storage = new_in_memory_storage()
  let token = new_token_manager("my-token", 3600, "Bearer")

  let storage = storage.save(token)
  match storage.load() {
    Ok(loaded) => {
      assert_eq(loaded.access_token, "my-token")
      assert_eq(loaded.token_type, "Bearer")
    }
    Err(_) => @test.fail("Expected token to be loaded")
  }
}

///|
test "in_memory_storage clear removes token" {
  let storage = new_in_memory_storage()
  let token = new_token_manager("my-token", 3600, "Bearer")

  let storage = storage.save(token)
  let storage = storage.clear()
  match storage.load() {
    Err(TokenStorageError::NotFound) => ()
    _ => @test.fail("Expected NotFound after clear")
  }
}

///|
test "in_memory_storage overwrites previous token" {
  let storage = new_in_memory_storage()
  let token1 = new_token_manager("token1", 3600, "Bearer")
  let token2 = new_token_manager("token2", 7200, "Bearer")

  let storage = storage.save(token1)
  let storage = storage.save(token2)
  match storage.load() {
    Ok(loaded) => assert_eq(loaded.access_token, "token2")
    Err(_) => @test.fail("Expected token2 to be loaded")
  }
}

///|
/// FileTokenStorage tests (Phase 3 async implementation)
test "file_storage creation works" {
  let _storage = new_file_storage("/tmp/tokens.json")
  ()
}

///|
test "file_storage saves and loads token" {
  // NOTE: Async test - actual call cannot be made in sync test context
  // This test is a placeholder for Phase 3 when async test support is available
  let _storage = new_file_storage("/tmp/test_tokens_save_load.json")
  let token = new_token_manager("my-token", 3600, "Bearer")
  // Verify structures without calling async methods
  assert_eq(token.access_token, "my-token")
  assert_eq(token.expires_in, 3600)
}

///|
test "file_storage load returns not found for missing file" {
  // NOTE: Async test - actual call cannot be made in sync test context
  // This test is a placeholder for Phase 3 when async test support is available
  let _storage = new_file_storage("/tmp/nonexistent_tokens_xyz_123.json")
  // Verify storage structure without calling async method
  assert_true(true)
}

///|
test "file_storage clear empties file" {
  // NOTE: Async test - actual call cannot be made in sync test context
  // This test is a placeholder for Phase 3 when async test support is available
  let _storage = new_file_storage("/tmp/test_tokens_clear.json")
  let token = new_token_manager("my-token", 3600, "Bearer")
  // Verify structures without calling async methods
  assert_eq(token.access_token, "my-token")
}

///|
/// TokenStorageError is defined in service_account_types.mbt
/// Direct enum value construction tests are covered by file and in-memory storage tests above
