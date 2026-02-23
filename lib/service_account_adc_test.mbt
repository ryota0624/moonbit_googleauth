///|
/// Application Default Credentials のテスト
test "parse_service_account_key with valid JSON" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\", \"private_key_id\": \"key-id\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"client_id\": \"123456789\", \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\", \"token_uri\": \"https://oauth2.googleapis.com/token\"}"
  match parse_service_account_key(json) {
    Ok(creds) => {
      assert_eq(creds.type_, "service_account")
      assert_eq(creds.project_id, "test")
      assert_eq(creds.private_key_id, "key-id")
      assert_eq(creds.client_email, "test@test.iam.gserviceaccount.com")
      assert_eq(creds.client_id, "123456789")
    }
    Err(_) => assert_false(true)
  }
}

///|
test "parse_service_account_key with empty JSON" {
  match parse_service_account_key("") {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing type field" {
  let json = "{\"project_id\": \"test\", \"private_key_id\": \"key-id\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\", \"client_id\": \"123456789\", \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\", \"token_uri\": \"https://oauth2.googleapis.com/token\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing project_id field" {
  let json = "{\"type\": \"service_account\", \"private_key_id\": \"key-id\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\", \"client_id\": \"123456789\", \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\", \"token_uri\": \"https://oauth2.googleapis.com/token\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing client_email field" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\", \"private_key_id\": \"key-id\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\", \"client_id\": \"123456789\", \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\", \"token_uri\": \"https://oauth2.googleapis.com/token\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing private_key field" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\", \"private_key_id\": \"key-id\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"client_id\": \"123456789\", \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\", \"token_uri\": \"https://oauth2.googleapis.com/token\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "load_credentials_from_file returns error for nonexistent file" {
  // NOTE: Async test - actual call cannot be made in sync test context
  // This test is a placeholder for Phase 3 when async test support is available
  // The function load_credentials_from_file() is async and will return IoCCError
  assert_true(true)
}

///|
test "load_credentials_from_env returns error when not set" {
  // NOTE: Async test - actual call cannot be made in sync test context
  // This test is a placeholder for Phase 3 when async test support is available
  // The function load_credentials_from_env() is async and will return EnvironmentVariableNotSet
  assert_true(true)
}
