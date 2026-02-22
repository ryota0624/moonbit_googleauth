///|
/// Google ヘルパー関数のテスト
test "parse_callback_url with valid code and state" {
  let url = "http://localhost:8080/callback?code=abc123&state=xyz789"
  match parse_callback_url(url) {
    Ok(_) => assert_true(true)
    Err(_) => assert_false(true)
  }
}

///|
test "parse_callback_url with multiple params" {
  let url = "http://localhost:8080/callback?code=test-code&state=test-state&scope=email"
  match parse_callback_url(url) {
    Ok(_) => assert_true(true)
    Err(_) => assert_false(true)
  }
}

///|
test "parse_callback_url missing code" {
  let url = "http://localhost:8080/callback?state=xyz789"
  match parse_callback_url(url) {
    Ok(_) => assert_false(true)
    Err(msg) => assert_true(msg.contains("code"))
  }
}

///|
test "parse_callback_url missing state" {
  let url = "http://localhost:8080/callback?code=abc123"
  match parse_callback_url(url) {
    Ok(_) => assert_false(true)
    Err(msg) => assert_true(msg.contains("state"))
  }
}

///|
test "parse_error_response with error" {
  let url = "http://localhost:8080/callback?error=access_denied&error_description=User+denied+access"
  match parse_error_response(url) {
    Some(_) => assert_true(true)
    None => assert_false(true)
  }
}

///|
test "parse_error_response without error" {
  let url = "http://localhost:8080/callback?code=abc123&state=xyz789"
  assert_eq(parse_error_response(url), None)
}
