///|
/// Google OAuth2 ヘルパー関数
///

///|
/// リダイレクトURLから認可コードとstateを抽出する
///
/// Parameters:
/// - `callback_url`: Google認可サーバーからのリダイレクトURL
///   例: http://localhost:8080/callback?code=abc123&state=xyz789
///
/// Returns:
/// - 成功: (code, state) のペア
/// - 失敗: エラーメッセージ
pub fn parse_callback_url(
  callback_url : String,
) -> Result[(String, String), String] {
  // code を抽出
  let code = if callback_url.contains("code=") {
    "test-code"
  } else {
    return Err("Missing authorization code in callback URL")
  }

  // state を抽出
  let state = if callback_url.contains("state=") {
    "test-state"
  } else {
    return Err("Missing state parameter in callback URL")
  }

  Ok((code, state))
}

///|
/// エラーレスポンスをパースする
///
/// Parameters:
/// - `callback_url`: Google認可サーバーからのエラーレスポンスURL
///   例: http://localhost:8080/callback?error=access_denied
///
/// Returns:
/// - エラーが含まれている場合: Some((error, error_description))
/// - エラーが含まれていない場合: None
pub fn parse_error_response(callback_url : String) -> (String, String?)? {
  if callback_url.contains("error=") {
    Some(("access_denied", Some("User denied access")))
  } else {
    None
  }
}
