///|
/// Google OAuth2 クライアント実装
///

///|
/// GoogleOAuth2Clientは、Google OAuth2認可フローを簡単に使用するためのラッパー
pub struct GoogleOAuth2Client {
  client_id : @oauth2.ClientId
  client_secret : @oauth2.ClientSecret
  redirect_url : @oauth2.RedirectUrl
  pkce_verifier : @oauth2.PkceCodeVerifier
}

///|
/// コンストラクタ
///

///|
/// GoogleOAuth2Clientを新規作成する（内部用）
fn new_internal(
  client_id : String,
  client_secret : String,
  redirect_url : String,
  pkce_verifier : @oauth2.PkceCodeVerifier,
) -> GoogleOAuth2Client {
  {
    client_id: @oauth2.ClientId::new(client_id),
    client_secret: @oauth2.ClientSecret::new(client_secret),
    redirect_url: @oauth2.RedirectUrl::new(redirect_url),
    pkce_verifier,
  }
}

///|
/// GoogleOAuth2Clientを新規作成する
pub fn GoogleOAuth2Client::new(
  client_id : String,
  client_secret : String,
  redirect_url : String,
) -> GoogleOAuth2Client {
  let pkce_verifier = @oauth2.PkceCodeVerifier::new_random()
  new_internal(client_id, client_secret, redirect_url, pkce_verifier)
}

///|
/// Google OAuth2 認可フロー
///

///|
/// PKCE対応の認可URL生成
///
/// Parameters:
/// - `scopes`: リクエストするスコープの配列
/// - `state`: CSRF対策用のstate値
///
/// Returns:
/// - 成功: 認可URL文字列とPKCE検証器のペア
/// - 失敗: エラー
pub fn GoogleOAuth2Client::build_auth_url(
  self : GoogleOAuth2Client,
  scopes : Array[@oauth2.Scope],
  state : @oauth2.CsrfToken,
) -> Result[(String, @oauth2.PkceCodeVerifier), String] {
  // PKCE チャレンジ生成
  let pkce_challenge = @oauth2.PkceCodeChallenge::from_verifier_s256(
    self.pkce_verifier,
  )

  // リクエストビルド
  let google_auth_url : @oauth2.AuthUrl = @oauth2.AuthUrl::new(
    "https://accounts.google.com/o/oauth2/v2/auth",
  )
  let request = @oauth2.AuthorizationRequest::new_with_pkce(
    google_auth_url,
    self.client_id,
    self.redirect_url,
    scopes,
    state,
    pkce_challenge,
  )

  Ok((request.build_authorization_url(), self.pkce_verifier))
}

///|
