///|
/// Application Default Credentials (ADC) 実装
///

///|
/// 環境変数からService Account認証情報を読み込む
///
/// GOOGLE_APPLICATION_CREDENTIALS環境変数で指定されたJSONファイルを読み込み、
/// Service Account認証情報をパースします。
///
/// Parameters:
/// - なし（環境変数から自動取得）
///
/// Returns:
/// - 成功: ServiceAccountCredentials
/// - 失敗: AdcError
///
pub async fn load_credentials_from_env() -> Result[
  ServiceAccountCredentials,
  AdcError,
] {
  match @sys.get_env_var("GOOGLE_APPLICATION_CREDENTIALS") {
    None => Err(EnvironmentVariableNotSet)
    Some(path) => load_credentials_from_file(path)
  }
}

///|
/// ファイルパスからService Account認証情報を読み込む
///
/// Parameters:
/// - `file_path`: Service Account JSONファイルのパス
///
/// Returns:
/// - 成功: ServiceAccountCredentials
/// - 失敗: AdcError
///
pub async fn load_credentials_from_file(
  file_path : String,
) -> Result[ServiceAccountCredentials, AdcError] {
  let data = @fs.read_file(file_path) catch {
    @fs.IOError(msg) => return Err(IoCCError(msg))
  }
  let json_str = data.text() catch {
    err => return Err(IoCCError(err.to_string()))
  }
  parse_service_account_key(json_str)
}

///|
/// JSONファイルのパーステスト用関数
///
/// Parameters:
/// - `json_str`: Service Account JSONの文字列表現
///
/// Returns:
/// - 成功: ServiceAccountCredentials
/// - 失敗: AdcError
pub fn parse_service_account_key(
  json_str : String,
) -> Result[ServiceAccountCredentials, AdcError] {
  if json_str.is_empty() {
    return Err(InvalidJson("Empty JSON string"))
  }

  // JSON文字列をパース
  let json = @json.parse(json_str) catch {
    _e => return Err(InvalidJson("Failed to parse JSON"))
  }

  // JSONオブジェクトとして処理
  let obj = match json {
    Object(o) => o
    _ => return Err(InvalidJson("Not a JSON object"))
  }

  // 必須フィールド抽出: type
  let type_ = match obj.get("type") {
    Some(String(s)) => s
    _ => return Err(MissingField("type"))
  }

  // 必須フィールド抽出: project_id
  let project_id = match obj.get("project_id") {
    Some(String(s)) => s
    _ => return Err(MissingField("project_id"))
  }

  // 必須フィールド抽出: private_key_id
  let private_key_id = match obj.get("private_key_id") {
    Some(String(s)) => s
    _ => return Err(MissingField("private_key_id"))
  }

  // 必須フィールド抽出: private_key
  let private_key = match obj.get("private_key") {
    Some(String(s)) => s
    _ => return Err(MissingField("private_key"))
  }

  // 必須フィールド抽出: client_email
  let client_email = match obj.get("client_email") {
    Some(String(s)) => s
    _ => return Err(MissingField("client_email"))
  }

  // 必須フィールド抽出: client_id
  let client_id = match obj.get("client_id") {
    Some(String(s)) => s
    _ => return Err(MissingField("client_id"))
  }

  // 必須フィールド抽出: auth_uri
  let auth_uri = match obj.get("auth_uri") {
    Some(String(s)) => s
    _ => return Err(MissingField("auth_uri"))
  }

  // 必須フィールド抽出: token_uri
  let token_uri = match obj.get("token_uri") {
    Some(String(s)) => s
    _ => return Err(MissingField("token_uri"))
  }

  // オプションフィールド抽出: auth_provider_x509_cert_url
  let auth_provider_x509_cert_url = match
    obj.get("auth_provider_x509_cert_url") {
    Some(String(s)) => Some(s)
    _ => None
  }

  // オプションフィールド抽出: client_x509_cert_url
  let client_x509_cert_url = match obj.get("client_x509_cert_url") {
    Some(String(s)) => Some(s)
    _ => None
  }

  Ok(ServiceAccountCredentials::{
    type_,
    project_id,
    private_key_id,
    private_key,
    client_email,
    client_id,
    auth_uri,
    token_uri,
    auth_provider_x509_cert_url,
    client_x509_cert_url,
  })
}

///|
/// JSON文字列から認証情報の種類を検出
///
/// Parameters:
/// - `json_str`: 認証情報JSONの文字列表現
///
/// Returns:
/// - 成功: 認証情報の種類を示す文字列 ("service_account" or "authorized_user")
/// - 失敗: AdcError
pub fn detect_credential_type(json_str : String) -> Result[String, AdcError] {
  if json_str.is_empty() {
    return Err(InvalidJson("Empty JSON string"))
  }
  let json = @json.parse(json_str) catch {
    _e => return Err(InvalidJson("Failed to parse JSON"))
  }
  let obj = match json {
    Object(o) => o
    _ => return Err(InvalidJson("Not a JSON object"))
  }
  match obj.get("type") {
    Some(String(s)) => Ok(s)
    _ => Err(MissingField("type"))
  }
}

///|
/// authorized_user JSONをパース
///
/// Parameters:
/// - `json_str`: authorized_user JSONの文字列表現
///
/// Returns:
/// - 成功: AuthorizedUserCredentials
/// - 失敗: AdcError
pub fn parse_authorized_user_key(
  json_str : String,
) -> Result[AuthorizedUserCredentials, AdcError] {
  if json_str.is_empty() {
    return Err(InvalidJson("Empty JSON string"))
  }
  let json = @json.parse(json_str) catch {
    _e => return Err(InvalidJson("Failed to parse JSON"))
  }
  let obj = match json {
    Object(o) => o
    _ => return Err(InvalidJson("Not a JSON object"))
  }
  let type_ = match obj.get("type") {
    Some(String(s)) => s
    _ => return Err(MissingField("type"))
  }
  let client_id = match obj.get("client_id") {
    Some(String(s)) => s
    _ => return Err(MissingField("client_id"))
  }
  let client_secret = match obj.get("client_secret") {
    Some(String(s)) => s
    _ => return Err(MissingField("client_secret"))
  }
  let refresh_token = match obj.get("refresh_token") {
    Some(String(s)) => s
    _ => return Err(MissingField("refresh_token"))
  }
  Ok(AuthorizedUserCredentials::{
    type_,
    client_id,
    client_secret,
    refresh_token,
  })
}

///|
/// AuthorizedUserCredentialsのコンストラクタ
pub fn new_authorized_user_credentials(
  type_ : String,
  client_id : String,
  client_secret : String,
  refresh_token : String,
) -> AuthorizedUserCredentials {
  AuthorizedUserCredentials::{ type_, client_id, client_secret, refresh_token }
}

///|
/// well-known locationのパスを取得
///
/// macOS/Linux: ~/.config/gcloud/application_default_credentials.json
/// Windows: %APPDATA%/gcloud/application_default_credentials.json
///
/// Returns:
/// - Some(path): パスが特定できた場合
/// - None: HOME/APPDATA環境変数が未設定の場合
pub fn get_well_known_credentials_path() -> String? {
  match @sys.get_env_var("HOME") {
    Some(home) =>
      Some(home + "/.config/gcloud/application_default_credentials.json")
    None =>
      match @sys.get_env_var("APPDATA") {
        Some(appdata) =>
          Some(appdata + "/gcloud/application_default_credentials.json")
        None => None
      }
  }
}

///|
/// ファイルパスから認証情報のJSON文字列を読み込み、種類を検出する
///
/// Parameters:
/// - `file_path`: 認証情報JSONファイルのパス
///
/// Returns:
/// - 成功: (credential_type, json_string) のペア
/// - 失敗: AdcError
pub async fn load_and_detect_credentials_from_file(
  file_path : String,
) -> Result[(String, String), AdcError] {
  let data = @fs.read_file(file_path) catch {
    @fs.IOError(msg) => return Err(IoCCError(msg))
  }
  let json_str = data.text() catch {
    err => return Err(IoCCError(err.to_string()))
  }
  match detect_credential_type(json_str) {
    Ok(cred_type) => Ok((cred_type, json_str))
    Err(e) => Err(e)
  }
}

///|
/// well-known locationから認証情報のJSON文字列を読み込む
///
/// Returns:
/// - 成功: (credential_type, json_string) のペア
/// - 失敗: AdcError
pub async fn load_json_from_well_known_location() -> Result[
  (String, String),
  AdcError,
] {
  let path = match get_well_known_credentials_path() {
    Some(p) => p
    None => return Err(WellKnownLocationNotFound)
  }
  if !@fs.exists(path) {
    return Err(WellKnownLocationNotFound)
  }
  let data = @fs.read_file(path) catch {
    @fs.IOError(msg) => return Err(IoCCError(msg))
  }
  let json_str = data.text() catch {
    err => return Err(IoCCError(err.to_string()))
  }
  match detect_credential_type(json_str) {
    Ok(cred_type) => Ok((cred_type, json_str))
    Err(e) => Err(e)
  }
}

///|
/// AuthorizedUser認証情報の妥当性を検証
pub fn validate_authorized_user_credentials(
  creds : AuthorizedUserCredentials,
) -> Result[Unit, AdcError] {
  if creds.type_ != "authorized_user" {
    return Err(InvalidJson("Invalid credential type: " + creds.type_))
  }
  if creds.client_id.is_empty() {
    return Err(MissingField("client_id cannot be empty"))
  }
  if creds.client_secret.is_empty() {
    return Err(MissingField("client_secret cannot be empty"))
  }
  if creds.refresh_token.is_empty() {
    return Err(MissingField("refresh_token cannot be empty"))
  }
  Ok(())
}

///|
/// AuthorizedUser認証情報を使ってアクセストークンを取得
///
/// refresh_tokenを使ってGoogleのトークンエンドポイントに
/// POSTリクエストを送信し、アクセストークンを取得します。
///
/// Parameters:
/// - `creds`: AuthorizedUserCredentials
///
/// Returns:
/// - 成功: アクセストークン文字列
/// - 失敗: AdcError
pub async fn exchange_refresh_token(
  creds : AuthorizedUserCredentials,
) -> Result[String, AdcError] {
  let params : Map[String, String] = {
    "grant_type": "refresh_token",
    "client_id": creds.client_id,
    "client_secret": creds.client_secret,
    "refresh_token": creds.refresh_token,
  }
  let body = @oauth2.build_form_urlencoded_body(params)
  let headers : Map[String, String] = {
    "Content-Type": "application/x-www-form-urlencoded",
  }
  let (response, response_body) = @http.post(
    "https://oauth2.googleapis.com/token",
    body,
    headers~,
  ) catch {
    err => return Err(IoCCError("HTTP request failed: " + err.to_string()))
  }
  if response.code < 200 || response.code >= 300 {
    let error_body = response_body.text() catch { _ => "<unreadable body>" }
    let err_msg = "Token exchange failed with status " +
      response.code.to_string() +
      ": " +
      error_body
    return Err(IoCCError(err_msg))
  }
  let body_text = response_body.text() catch {
    err =>
      return Err(IoCCError("Failed to read response body: " + err.to_string()))
  }
  let json = @json.parse(body_text) catch {
    _e => return Err(InvalidJson("Failed to parse token response JSON"))
  }
  let obj = match json {
    Object(o) => o
    _ => return Err(InvalidJson("Token response is not a JSON object"))
  }
  match obj.get("access_token") {
    Some(String(token)) => Ok(token)
    _ => Err(MissingField("access_token not found in token response"))
  }
}

///|
/// バリデーション関数
///

///|
/// Service Account認証情報の妥当性を検証
pub fn validate_credentials(
  creds : ServiceAccountCredentials,
) -> Result[Unit, AdcError] {
  // 型の確認
  if creds.type_ != "service_account" {
    return Err(InvalidJson("Invalid service account type: " + creds.type_))
  }

  // プロジェクトIDの確認
  if creds.project_id.is_empty() {
    return Err(MissingField("project_id cannot be empty"))
  }

  // client_email の確認
  if !creds.client_email.contains("@") {
    return Err(InvalidJson("Invalid client_email format"))
  }

  // private_key の確認
  if !creds.private_key.contains("PRIVATE KEY") {
    return Err(InvalidJson("Invalid private_key format: must be PEM encoded"))
  }

  Ok(())
}
