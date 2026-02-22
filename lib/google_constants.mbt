///|
/// Google OAuth2エンドポイント定数
///

///|
/// Google認証エンドポイント
pub let auth_url : @oauth2.AuthUrl = @oauth2.AuthUrl::new(
  "https://accounts.google.com/o/oauth2/v2/auth",
)

///|
/// Googleトークンエンドポイント
pub let token_url : @oauth2.TokenUrl = @oauth2.TokenUrl::new(
  "https://oauth2.googleapis.com/token",
)

///|
/// Googleトークン失効エンドポイント
pub let revoke_url : String = "https://oauth2.googleapis.com/revoke"

///|
/// Google UserInfo エンドポイント
pub let userinfo_url : String = "https://www.googleapis.com/oauth2/v2/userinfo"

///|
/// 一般的なスコープ定数
///

///|
/// ユーザーメールアドレス（読み取り）
pub let scope_userinfo_email : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/userinfo.email",
)

///|
/// ユーザープロフィール（読み取り）
pub let scope_userinfo_profile : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/userinfo.profile",
)

///|
/// Google Driveフルアクセス
pub let scope_drive : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/drive",
)

///|
/// Google Drive読み取り専用
pub let scope_drive_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/drive.readonly",
)

///|
/// Google Drive ファイルメタデータ読み取り
pub let scope_drive_metadata_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/drive.metadata.readonly",
)

///|
/// Gmailメール読み取り
pub let scope_gmail_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/gmail.readonly",
)

///|
/// Gmailメール送信
pub let scope_gmail_send : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/gmail.send",
)

///|
/// Gmailメール変更
pub let scope_gmail_modify : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/gmail.modify",
)

///|
/// Google Calendarフルアクセス
pub let scope_calendar : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/calendar",
)

///|
/// Google Calendar読み取り専用
pub let scope_calendar_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/calendar.readonly",
)

///|
/// Google Contacts読み取り
pub let scope_contacts_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/contacts.readonly",
)

///|
/// Google Contacts
pub let scope_contacts : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/contacts",
)

///|
/// Google Sheets
pub let scope_spreadsheets : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/spreadsheets",
)

///|
/// Google Sheets読み取り専用
pub let scope_spreadsheets_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/spreadsheets.readonly",
)

///|
/// Google Docs
pub let scope_documents : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/documents",
)

///|
/// Google Docs読み取り専用
pub let scope_documents_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/documents.readonly",
)

///|
/// Google YouTubeアップロード
pub let scope_youtube_upload : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/youtube.upload",
)

///|
/// Google YouTube読み取り
pub let scope_youtube_readonly : @oauth2.Scope = @oauth2.Scope::new(
  "https://www.googleapis.com/auth/youtube.readonly",
)

///|
/// OpenID Connect
pub let scope_openid : @oauth2.Scope = @oauth2.Scope::new("openid")

///|
/// ヘルパー関数
///

///|
/// よく使われるスコープの組み合わせを返す（ユーザー情報取得）
pub fn basic_scopes() -> Array[@oauth2.Scope] {
  [scope_userinfo_email, scope_userinfo_profile]
}

///|
/// Google Drive関連のスコープを返す
pub fn drive_scopes() -> Array[@oauth2.Scope] {
  [scope_drive]
}

///|
/// Gmail関連のスコープを返す
pub fn gmail_scopes() -> Array[@oauth2.Scope] {
  [scope_gmail_readonly, scope_gmail_send]
}

///|
/// Google Calendar関連のスコープを返す
pub fn calendar_scopes() -> Array[@oauth2.Scope] {
  [scope_calendar]
}
