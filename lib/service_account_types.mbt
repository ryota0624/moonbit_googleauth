///|
/// Service Account 共通型定義
///

///|
/// Google Service Account の認証情報
pub struct ServiceAccountCredentials {
  type_ : String
  project_id : String
  private_key_id : String
  private_key : String
  client_email : String
  client_id : String
  auth_uri : String
  token_uri : String
  auth_provider_x509_cert_url : String?
  client_x509_cert_url : String?
}

///|
/// Metadata Server 設定
pub struct MetadataServerConfig {
  pub base_url : String
  pub timeout_ms : Int
}

///|
/// エラー型定義
///

///|
/// Application Default Credentials (ADC) 関連エラー
pub enum AdcError {
  EnvironmentVariableNotSet
  FileNotFound(String)
  InvalidJson(String)
  MissingField(String)
  IoCCError(String)
}

///|
/// Metadata Server 関連エラー
pub enum MetadataError {
  MetadataServerUnavailable
  InvalidResponse(String)
  HttpError(Int, String)
  Timeout
  ParsingError(String)
}

///|
/// Client Credentials 関連エラー
pub enum ClientCredentialsError {
  InvalidCredentials(String)
  TokenExchangeFailed(String)
  NetworkError(String)
}

///|
/// 認証タイプ
pub enum AuthCredentialsType {
  ServiceAccount
  MetadataServer
  ClientCredentials
}

///|
/// 統合認証エラー型
pub enum AuthenticationError {
  NoValidCredentials
  AdcError(String)
  MetadataServerError(String)
  ClientCredentialsError(String)
  InvalidCredentials(String)
}

///|
/// Token Storage 関連エラー
pub enum TokenStorageError {
  StorageNotAvailable(String)
  SerializationError(String)
  DeserializationError(String)
  NotFound
}
