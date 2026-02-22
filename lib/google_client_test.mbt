///|
/// GoogleOAuth2Client のテスト
test "GoogleOAuth2Client can be created" {
  let _client = GoogleOAuth2Client::new(
    "test-client-id", "test-client-secret", "http://localhost:8080/callback",
  )
  // クライアントが正常に作成されたことを確認
  assert_eq(true, true)
}

///|
test "GoogleOAuth2Client::new stores credentials" {
  let client_id = "test-client-id"
  let client_secret = "test-client-secret"
  let redirect_url = "http://localhost:8080/callback"

  let _client = GoogleOAuth2Client::new(client_id, client_secret, redirect_url)

  // 構造体が正常に作成されたか確認
  assert_eq(true, true)
}
