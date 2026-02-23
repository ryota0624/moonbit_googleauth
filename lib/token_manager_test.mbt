///|
/// TokenManager tests
test "new_token_manager creates instance with correct values" {
  let manager = new_token_manager("test-token", 3600, "Bearer")
  assert_eq(manager.access_token, "test-token")
  assert_eq(manager.expires_in, 3600)
  assert_eq(manager.issued_at_offset, 0)
  assert_eq(manager.token_type, "Bearer")
}

///|
test "is_expired returns false when token is valid" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=1000, expires=3600 -> valid
  assert_false(manager.is_expired(1000))
}

///|
test "is_expired returns true when token has expired" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=4000, expires=3600 -> expired
  assert_true(manager.is_expired(4000))
}

///|
test "is_expired returns true at exact expiry time" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=3600, expires=3600 -> expired
  assert_true(manager.is_expired(3600))
}

///|
test "is_expired returns false just before expiry" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=3599, expires=3600 -> valid
  assert_false(manager.is_expired(3599))
}

///|
test "needs_refresh returns false when plenty of time remains" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=1000, expires=3600, remaining=2600 -> false
  assert_false(manager.needs_refresh(1000))
}

///|
test "needs_refresh returns true within 5 minutes of expiry" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=3400, expires=3600, remaining=200 -> true
  assert_true(manager.needs_refresh(3400))
}

///|
test "needs_refresh returns false when already expired" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=4000, expires=3600 -> expired
  assert_false(manager.needs_refresh(4000))
}

///|
test "needs_refresh returns true at exactly 5 minutes before expiry" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=3300, expires=3600, remaining=300 -> false (not less than 300)
  assert_false(manager.needs_refresh(3300))
  // At 299 seconds remaining should return true
  assert_true(manager.needs_refresh(3301))
}

///|
test "get_token returns access token" {
  let manager = new_token_manager("my-secret-token", 3600, "Bearer")
  assert_eq(manager.get_token(), "my-secret-token")
}

///|
test "remaining_seconds returns correct time until expiry" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=1000, expires=3600, remaining=2600
  assert_eq(manager.remaining_seconds(1000), 2600)
}

///|
test "remaining_seconds returns negative when expired" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=4000, expires=3600, remaining=-400
  assert_eq(manager.remaining_seconds(4000), -400)
}

///|
test "remaining_seconds returns zero at exact expiry" {
  let manager = new_token_manager("my-token", 3600, "Bearer")
  // issued_at=0, current=3600, expires=3600, remaining=0
  assert_eq(manager.remaining_seconds(3600), 0)
}

///|
test "token manager works with short-lived tokens" {
  let manager = new_token_manager("short-token", 300, "Bearer")
  // Token valid for only 5 minutes
  assert_false(manager.is_expired(100))
  assert_false(manager.is_expired(299))
  assert_true(manager.is_expired(300))
}

///|
test "token manager works with long-lived tokens" {
  let manager = new_token_manager("long-token", 86400, "Bearer")
  // Token valid for 24 hours
  assert_false(manager.is_expired(43200))
  assert_false(manager.is_expired(86399))
  assert_true(manager.is_expired(86400))
}

///|
test "needs_refresh buffer is exactly 300 seconds" {
  let manager = new_token_manager("my-token", 1000, "Bearer")
  // 301 seconds remaining: should not need refresh
  assert_false(manager.needs_refresh(699))
  // 299 seconds remaining: should need refresh
  assert_true(manager.needs_refresh(701))
}

///|
/// Unix Timestamp Support Tests (Phase 4)
test "new_token_manager_with_timestamp creates instance with Unix timestamp" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  assert_eq(manager.access_token, "test-token")
  assert_eq(manager.expires_in, 3600)
  assert_eq(manager.token_type, "Bearer")
  assert_true(manager.get_issued_at_timestamp() is Some(_))
}

///|
test "get_issued_at_timestamp returns stored Unix timestamp" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  assert_true(manager.get_issued_at_timestamp() is Some(1640000000))
}

///|
test "get_issued_at_timestamp returns None for offset-based tokens" {
  let manager = new_token_manager("test-token", 3600, "Bearer")
  assert_true(manager.get_issued_at_timestamp() is None)
}

///|
test "get_expiry_timestamp calculates expiry time correctly" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  match manager.get_expiry_timestamp() {
    Some(ts) => assert_eq(ts, 1640003600)
    None => assert_true(false)
  }
}

///|
test "get_expiry_timestamp returns None for offset-based tokens" {
  let manager = new_token_manager("test-token", 3600, "Bearer")
  assert_true(manager.get_expiry_timestamp() is None)
}

///|
test "is_expired_at_timestamp returns false when token is valid" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600, checking at 1640001000 -> valid
  assert_false(manager.is_expired_at_timestamp(1640001000))
}

///|
test "is_expired_at_timestamp returns true when token has expired" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600, checking at 1640004000 -> expired
  assert_true(manager.is_expired_at_timestamp(1640004000))
}

///|
test "is_expired_at_timestamp returns true at exact expiry time" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600
  assert_true(manager.is_expired_at_timestamp(1640003600))
}

///|
test "is_expired_at_timestamp returns false for offset-based tokens (conservative)" {
  let manager = new_token_manager("test-token", 3600, "Bearer")
  // Offset-based tokens without timestamp info are conservatively treated as not expired
  assert_false(manager.is_expired_at_timestamp(2000000000))
}

///|
test "needs_refresh_at_timestamp returns true within 5 minutes of expiry" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600
  // At 1640003400, 200 seconds remaining -> should refresh
  assert_true(manager.needs_refresh_at_timestamp(1640003400))
}

///|
test "needs_refresh_at_timestamp returns false with plenty of time" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600
  // At 1640001000, 2600 seconds remaining -> should not refresh
  assert_false(manager.needs_refresh_at_timestamp(1640001000))
}

///|
test "remaining_seconds_at_timestamp calculates correctly" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600
  // At 1640001000, remaining = 2600
  assert_eq(manager.remaining_seconds_at_timestamp(1640001000), 2600)
}

///|
test "remaining_seconds_at_timestamp returns negative when expired" {
  let manager = new_token_manager_with_timestamp(
    "test-token", 3600, 1640000000, "Bearer",
  )
  // Token issued at 1640000000, expires at 1640003600
  // At 1640004000, remaining = -400
  assert_eq(manager.remaining_seconds_at_timestamp(1640004000), -400)
}

///|
test "remaining_seconds_at_timestamp returns conservative value for offset tokens" {
  let manager = new_token_manager("test-token", 3600, "Bearer")
  // Offset-based tokens without timestamp info return large positive value
  assert_true(manager.remaining_seconds_at_timestamp(2000000000) > 1000000000)
}

///|
/// Response Metadata Tests (Phase 4)
test "new_token_manager_from_response creates manager with response metadata" {
  let response = new_token_response(
    "response-token",
    7200,
    "Bearer",
    Some("read write"),
  )
  let manager = new_token_manager_from_response(response, 1640000000)
  assert_eq(manager.access_token, "response-token")
  assert_eq(manager.expires_in, 7200)
  assert_eq(manager.token_type, "Bearer")
  assert_true(manager.get_issued_at_timestamp() is Some(1640000000))
}

///|
test "new_token_manager_from_response uses actual expires_in from response" {
  let response_short = new_token_response("token1", 600, "Bearer", None)
  let response_long = new_token_response("token2", 86400, "Bearer", None)
  let manager_short = new_token_manager_from_response(
    response_short, 1640000000,
  )
  let manager_long = new_token_manager_from_response(response_long, 1640000000)

  // Both should be valid at the same current time
  assert_false(manager_short.is_expired_at_timestamp(1640000500))
  assert_false(manager_long.is_expired_at_timestamp(1640000500))

  // Short token should expire sooner
  assert_true(manager_short.is_expired_at_timestamp(1640000700))
  assert_false(manager_long.is_expired_at_timestamp(1640000700))
}

///|
test "new_token_manager_from_response handles variable scope metadata" {
  let response_with_scope = new_token_response(
    "token",
    3600,
    "Bearer",
    Some("https://www.googleapis.com/auth/drive"),
  )
  let response_no_scope = new_token_response("token", 3600, "Bearer", None)
  // Both should create valid managers regardless of scope
  let m1 = new_token_manager_from_response(response_with_scope, 1640000000)
  let m2 = new_token_manager_from_response(response_no_scope, 1640000000)
  assert_eq(m1.expires_in, 3600)
  assert_eq(m2.expires_in, 3600)
}

///|
test "response metadata extraction enables accurate token lifecycle tracking" {
  // Simulate getting 10-minute token from endpoint
  let response = new_token_response(
    "short-lived-token",
    600,
    "Bearer",
    Some("openid email profile"),
  )
  let timestamp = 1640000000
  let manager = new_token_manager_from_response(response, timestamp)

  // At exactly 5 minutes (300 seconds) remaining: should not need refresh
  let five_min_later = timestamp + 300
  assert_false(manager.needs_refresh_at_timestamp(five_min_later))

  // Just after 5 minutes (299 seconds remaining): should need refresh
  let just_after_five_min = timestamp + 301
  assert_true(manager.needs_refresh_at_timestamp(just_after_five_min))

  // After 10 minutes, should be expired
  let ten_min_later = timestamp + 600
  assert_true(manager.is_expired_at_timestamp(ten_min_later))
}
