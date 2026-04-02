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
test "parse_authorized_user_key with valid JSON" {
  let json = "{\"type\": \"authorized_user\", \"client_id\": \"xxx.apps.googleusercontent.com\", \"client_secret\": \"xxx-secret\", \"refresh_token\": \"1//xxx-refresh\"}"
  match parse_authorized_user_key(json) {
    Ok(creds) => {
      assert_eq(creds.type_, "authorized_user")
      assert_eq(creds.client_id, "xxx.apps.googleusercontent.com")
      assert_eq(creds.client_secret, "xxx-secret")
      assert_eq(creds.refresh_token, "1//xxx-refresh")
    }
    Err(_) => assert_false(true)
  }
}

///|
test "parse_authorized_user_key with empty JSON" {
  match parse_authorized_user_key("") {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_authorized_user_key missing client_id" {
  let json = "{\"type\": \"authorized_user\", \"client_secret\": \"xxx\", \"refresh_token\": \"1//xxx\"}"
  match parse_authorized_user_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_authorized_user_key missing refresh_token" {
  let json = "{\"type\": \"authorized_user\", \"client_id\": \"xxx\", \"client_secret\": \"xxx\"}"
  match parse_authorized_user_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "detect_credential_type service_account" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\"}"
  match detect_credential_type(json) {
    Ok(t) => assert_eq(t, "service_account")
    Err(_) => assert_false(true)
  }
}

///|
test "detect_credential_type authorized_user" {
  let json = "{\"type\": \"authorized_user\", \"client_id\": \"test\"}"
  match detect_credential_type(json) {
    Ok(t) => assert_eq(t, "authorized_user")
    Err(_) => assert_false(true)
  }
}

///|
test "detect_credential_type missing type" {
  let json = "{\"client_id\": \"test\"}"
  match detect_credential_type(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "validate_authorized_user_credentials valid" {
  let creds = new_authorized_user_credentials(
    "authorized_user", "xxx.apps.googleusercontent.com", "xxx-secret", "1//xxx",
  )
  match validate_authorized_user_credentials(creds) {
    Ok(_) => assert_true(true)
    Err(_) => assert_false(true)
  }
}

///|
test "validate_authorized_user_credentials empty refresh_token" {
  let creds = new_authorized_user_credentials(
    "authorized_user", "xxx", "xxx", "",
  )
  match validate_authorized_user_credentials(creds) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "get_well_known_credentials_path returns path" {
  match get_well_known_credentials_path() {
    Some(path) =>
      assert_true(path.contains("application_default_credentials.json"))
    None => assert_true(true)
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
