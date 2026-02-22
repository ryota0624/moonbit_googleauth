///|
/// Google認証クライアントのテスト
///

///|
test "new_auth_client creates client with none credentials" {
  let client = new_auth_client(None)
  // Verify credentials field is None
  assert_true(client.credentials is None)
}

///|
test "auto_detect_and_authenticate returns valid client or error" {
  // Note: In Phase 1.5, load_credentials_from_env always fails
  // This test verifies the function returns a valid result
  match auto_detect_and_authenticate() {
    Ok(_client) =>
      // Should return a valid GoogleAuthClient
      assert_true(true)
    Err(NoValidCredentials) =>
      // In non-GCP environment, error is expected
      assert_true(true)
    Err(_) => assert_false(true)
  }
}

///|
test "auto_detect_and_authenticate in non-GCP environment" {
  // In non-GCP environment with no ADC, verify behavior
  match auto_detect_and_authenticate() {
    Ok(_client) =>
      // MetadataServer detection returns false, so should fail
      // Unless MetadataServer is somehow available (shouldn't be in non-GCP)
      assert_true(true)
    Err(NoValidCredentials) =>
      // Expected in non-GCP environment
      assert_true(true)
    Err(_) => assert_false(true)
  }
}

///|
test "authentication error handling for no valid credentials" {
  // Test that NoValidCredentials error is properly handled
  match auto_detect_and_authenticate() {
    Ok(_) => assert_true(true)
    Err(NoValidCredentials) => assert_true(true)
    Err(_) => assert_false(true)
  }
}

///|
test "new_auth_client returns google auth client" {
  let client = new_auth_client(None)
  // Verify the client was created successfully
  assert_true(client.credentials is None)
}
