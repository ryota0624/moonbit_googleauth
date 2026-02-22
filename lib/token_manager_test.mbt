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
