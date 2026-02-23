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
pub fn load_credentials_from_env() -> Result[
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
pub fn load_credentials_from_file(
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
