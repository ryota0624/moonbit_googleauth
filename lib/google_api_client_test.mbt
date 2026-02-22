///|
/// GoogleApiClient tests
test "new_api_client creates unauthenticated client" {
  let auth_client = new_auth_client(None)
  let api_client = new_api_client(auth_client)
  assert_false(api_client.is_authenticated())
}

///|
test "is_authenticated returns false for new client" {
  let auth_client = new_auth_client(None)
  let api_client = new_api_client(auth_client)
  assert_false(api_client.is_authenticated())
}

///|
test "get_valid_token fails when not authenticated" {
  let auth_client = new_auth_client(None)
  let api_client = new_api_client(auth_client)

  match api_client.get_valid_token(0) {
    Err(InvalidCredentials(_)) => ()
    _ => @test.fail("Expected InvalidCredentials error")
  }
}

///|
test "get_valid_token returns token when valid" {
  let auth_client = new_auth_client(None)
  let manager = new_token_manager("my-valid-token", 3600, "Bearer")
  let api_client = new_api_client_with_token(auth_client, manager)

  match api_client.get_valid_token(1000) {
    Ok(token) => assert_eq(token, "my-valid-token")
    Err(_) => @test.fail("Expected token to be returned")
  }
}

///|
test "get_valid_token fails when token expired" {
  let auth_client = new_auth_client(None)
  let manager = new_token_manager("expired-token", 3600, "Bearer")
  let api_client = new_api_client_with_token(auth_client, manager)

  match api_client.get_valid_token(4000) {
    Err(InvalidCredentials(_)) => ()
    _ => @test.fail("Expected InvalidCredentials error for expired token")
  }
}

///|
test "is_authenticated returns true with token" {
  let auth_client = new_auth_client(None)
  let manager = new_token_manager("test-token", 3600, "Bearer")
  let api_client = new_api_client_with_token(auth_client, manager)

  assert_true(api_client.is_authenticated())
}

///|
test "get_valid_token works with different token values" {
  let auth_client = new_auth_client(None)

  let manager1 = new_token_manager("token-abc", 3600, "Bearer")
  let client1 = new_api_client_with_token(auth_client, manager1)

  match client1.get_valid_token(1000) {
    Ok(token) => assert_eq(token, "token-abc")
    Err(_) => @test.fail("Expected token-abc")
  }

  let manager2 = new_token_manager("token-xyz", 3600, "Bearer")
  let client2 = new_api_client_with_token(auth_client, manager2)

  match client2.get_valid_token(1000) {
    Ok(token) => assert_eq(token, "token-xyz")
    Err(_) => @test.fail("Expected token-xyz")
  }
}

///|
test "token validity boundary conditions" {
  let auth_client = new_auth_client(None)

  // Token expires at offset 3600
  let manager = new_token_manager("boundary-token", 3600, "Bearer")
  let client = new_api_client_with_token(auth_client, manager)

  // Just before expiry
  match client.get_valid_token(3599) {
    Ok(token) => assert_eq(token, "boundary-token")
    Err(_) => @test.fail("Token should be valid at 3599")
  }

  // At expiry
  match client.get_valid_token(3600) {
    Err(InvalidCredentials(_)) => ()
    _ => @test.fail("Token should be expired at 3600")
  }
}

///|
test "refresh_token_if_needed returns same client when token valid" {
  let auth_client = new_auth_client(None)
  let manager = new_token_manager("my-token", 3600, "Bearer")
  let client = new_api_client_with_token(auth_client, manager)

  match client.refresh_token_if_needed(1000) {
    Ok(updated) =>
      match updated.get_valid_token(1000) {
        Ok(token) => assert_eq(token, "my-token")
        Err(_) => @test.fail("Expected valid token")
      }
    Err(_) => @test.fail("Expected refresh to succeed")
  }
}

///|
test "refresh_token_if_needed attempts auth when not authenticated" {
  let auth_client = new_auth_client(None)
  let api_client = new_api_client(auth_client)

  // Will fail because get_access_token not fully implemented in Phase 1.5
  match api_client.refresh_token_if_needed(0) {
    Ok(_) => @test.fail("Expected authentication to fail (not implemented)")
    Err(InvalidCredentials(_)) =>
      // Expected in Phase 1.5 - get_access_token returns error
      ()
    Err(_) => ()
  }
}
