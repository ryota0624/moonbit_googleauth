///|
/// Application Default Credentials のテスト
test "parse_service_account_key with valid JSON" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_true(true)
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
  let json = "{\"project_id\": \"test\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing project_id field" {
  let json = "{\"type\": \"service_account\", \"client_email\": \"test@test.iam.gserviceaccount.com\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing client_email field" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\", \"private_key\": \"-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}

///|
test "parse_service_account_key missing private_key field" {
  let json = "{\"type\": \"service_account\", \"project_id\": \"test\", \"client_email\": \"test@test.iam.gserviceaccount.com\"}"
  match parse_service_account_key(json) {
    Ok(_) => assert_false(true)
    Err(_) => assert_true(true)
  }
}
