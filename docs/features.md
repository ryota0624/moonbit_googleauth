# Google OAuth2認証ライブラリ 機能仕様書

## 1. 概要

MoonBit用のGoogle OAuth2認証ライブラリの必要機能を定義します。

## 2. コア機能

### 2.1 クライアント設定管理

#### 2.1.1 OAuth2Config型

**目的:** OAuth2認証に必要な設定情報を管理

**必要なフィールド:**
```moonbit
struct OAuth2Config {
  client_id: String          // Google Cloud Consoleから取得したクライアントID
  client_secret: String      // クライアントシークレット
  auth_url: String          // 認可エンドポイント（デフォルト: accounts.google.com/o/oauth2/v2/auth）
  token_url: String         // トークンエンドポイント（デフォルト: oauth2.googleapis.com/token）
  redirect_url: String      // 認証後のリダイレクト先URI
  scopes: Array[String]     // 要求するスコープのリスト
}
```

**必要なメソッド:**
- `new()` - 基本設定でConfigを作成
- `with_scopes()` - スコープを追加
- `validate()` - 設定の妥当性を検証

#### 2.1.2 デフォルト値の提供

Google OAuth2の標準エンドポイントをデフォルトとして提供:
- `default_auth_url()` - `https://accounts.google.com/o/oauth2/v2/auth`
- `default_token_url()` - `https://oauth2.googleapis.com/token`
- `default_revoke_url()` - `https://oauth2.googleapis.com/revoke`

### 2.2 認可フロー

#### 2.2.1 認可URLの生成

**目的:** ユーザーをGoogle認証ページにリダイレクトするURLを生成

**必要なパラメータ:**
- `client_id` - クライアントID
- `redirect_uri` - リダイレクトURI
- `response_type` - 固定値 "code"
- `scope` - 要求するスコープ（スペース区切り）
- `state` - CSRF対策用のランダム文字列
- `access_type` (オプション) - "offline" でリフレッシュトークンを取得
- `prompt` (オプション) - "consent" で常に同意画面を表示
- `include_granted_scopes` (オプション) - 増分認可

**実装:**
```moonbit
fn generate_auth_url(config: OAuth2Config, state: String, options: AuthUrlOptions) -> String
```

**セキュリティ要件:**
- state パラメータは暗号学的に安全な乱数で生成
- HTTPSを強制（localhost除く）
- URLエンコーディングを適切に実施

#### 2.2.2 認可コードの処理

**目的:** リダイレクトバックされたURLから認可コードを抽出

**入力:**
- リダイレクト先のURL（クエリパラメータ付き）

**処理:**
1. URLからクエリパラメータをパース
2. `code` パラメータを取得
3. `state` パラメータを検証（CSRF対策）
4. `error` パラメータの有無を確認

**実装:**
```moonbit
fn parse_authorization_response(url: String, expected_state: String) -> Result[String, OAuth2Error]
```

**エラーハンドリング:**
- state不一致エラー
- errorパラメータが返された場合のエラー
- 不正なURLフォーマット

### 2.3 トークン管理

#### 2.3.1 アクセストークンの取得

**目的:** 認可コードをアクセストークンに交換

**リクエスト:**
- エンドポイント: `token_url`
- メソッド: POST
- Content-Type: `application/x-www-form-urlencoded`

**リクエストパラメータ:**
```
code={authorization_code}
client_id={client_id}
client_secret={client_secret}
redirect_uri={redirect_uri}
grant_type=authorization_code
```

**レスポンス:**
```moonbit
struct TokenResponse {
  access_token: String
  expires_in: Int           // 有効期限（秒）
  refresh_token: Option[String]  // offline時のみ
  scope: String            // スペース区切りのスコープ
  token_type: String       // "Bearer"
}
```

**実装:**
```moonbit
fn exchange_code_for_token(
  config: OAuth2Config,
  code: String
) -> Result[TokenResponse, OAuth2Error]
```

#### 2.3.2 トークンのリフレッシュ

**目的:** リフレッシュトークンを使って新しいアクセストークンを取得

**リクエストパラメータ:**
```
refresh_token={refresh_token}
client_id={client_id}
client_secret={client_secret}
grant_type=refresh_token
```

**実装:**
```moonbit
fn refresh_access_token(
  config: OAuth2Config,
  refresh_token: String
) -> Result[TokenResponse, OAuth2Error]
```

#### 2.3.3 トークンの失効

**目的:** アクセストークンまたはリフレッシュトークンを無効化

**リクエスト:**
- エンドポイント: `https://oauth2.googleapis.com/revoke`
- メソッド: POST
- Content-Type: `application/x-www-form-urlencoded`

**リクエストパラメータ:**
```
token={token}
```

**実装:**
```moonbit
fn revoke_token(token: String) -> Result[Unit, OAuth2Error]
```

#### 2.3.4 トークンの有効期限管理

**目的:** トークンの有効期限を追跡し、自動リフレッシュを支援

**必要な型:**
```moonbit
struct Token {
  access_token: String
  refresh_token: Option[String]
  expires_at: Int64        // Unix timestamp
  scope: String
  token_type: String
}
```

**必要なメソッド:**
- `is_expired()` - トークンが期限切れか判定
- `needs_refresh()` - リフレッシュが必要か判定（期限の90%経過など）
- `from_response()` - TokenResponseからTokenを生成

### 2.4 エラーハンドリング

#### 2.4.1 OAuth2Error型

**目的:** OAuth2認証で発生する可能性のあるエラーを表現

```moonbit
enum OAuth2Error {
  InvalidRequest(String)           // リクエストが不正
  UnauthorizedClient(String)       // クライアント認証失敗
  AccessDenied(String)            // ユーザーが拒否
  UnsupportedResponseType(String) // レスポンスタイプ未サポート
  InvalidScope(String)            // スコープが不正
  ServerError(String)             // サーバーエラー
  TemporarilyUnavailable(String)  // 一時的に利用不可
  InvalidGrant(String)            // 認可コードが不正または期限切れ
  InvalidToken(String)            // トークンが不正
  NetworkError(String)            // ネットワークエラー
  ParseError(String)              // レスポンスのパースエラー
  StateVerificationFailed(String) // state検証失敗
}
```

#### 2.4.2 エラーレスポンスのパース

Googleからのエラーレスポンスを適切にパース:
```json
{
  "error": "invalid_grant",
  "error_description": "Token has been expired or revoked."
}
```

### 2.5 HTTPクライアント統合

#### 2.5.1 mioライブラリの統合

**必要な機能:**
- POST リクエストの送信
- Content-Type ヘッダーの設定
- URLエンコードされたボディの送信
- JSONレスポンスのパース
- HTTPステータスコードの確認

**実装例:**
```moonbit
fn make_token_request(
  url: String,
  params: Map[String, String]
) -> Result[TokenResponse, OAuth2Error]
```

### 2.6 ユーティリティ機能

#### 2.6.1 state生成

**目的:** CSRF対策用のランダムな state 文字列を生成

**要件:**
- 暗号学的に安全な乱数生成
- 十分な長さ（推奨: 32文字以上）
- URL安全な文字セット

**実装:**
```moonbit
fn generate_state() -> String
```

#### 2.6.2 URLエンコーディング

**目的:** クエリパラメータとボディパラメータのエンコード

**実装:**
```moonbit
fn url_encode(value: String) -> String
fn build_query_string(params: Map[String, String]) -> String
```

#### 2.6.3 スコープ管理

**目的:** 一般的なGoogle APIスコープの定義と管理

**定数定義:**
```moonbit
// Google Drive
let scope_drive_readonly = "https://www.googleapis.com/auth/drive.readonly"
let scope_drive = "https://www.googleapis.com/auth/drive"

// Gmail
let scope_gmail_readonly = "https://www.googleapis.com/auth/gmail.readonly"
let scope_gmail_send = "https://www.googleapis.com/auth/gmail.send"

// Calendar
let scope_calendar = "https://www.googleapis.com/auth/calendar"
let scope_calendar_readonly = "https://www.googleapis.com/auth/calendar.readonly"

// User Info
let scope_userinfo_email = "https://www.googleapis.com/auth/userinfo.email"
let scope_userinfo_profile = "https://www.googleapis.com/auth/userinfo.profile"
```

## 3. 高度な機能（オプション）

### 3.1 PKCE (Proof Key for Code Exchange)

**目的:** 認可コード横取り攻撃を防ぐ（モバイルアプリやSPAで推奨）

**実装:**
- `code_verifier` の生成（43-128文字のランダム文字列）
- `code_challenge` の生成（SHA256ハッシュ + Base64URL）
- トークン交換時に `code_verifier` を送信

### 3.2 トークンストレージ

**目的:** トークンを永続化して再利用

**実装案:**
```moonbit
trait TokenStorage {
  fn save(token: Token) -> Result[Unit, StorageError]
  fn load() -> Result[Option[Token], StorageError]
  fn delete() -> Result[Unit, StorageError]
}
```

### 3.3 自動トークンリフレッシュ

**目的:** API呼び出し前に自動的にトークンをリフレッシュ

**実装:**
```moonbit
struct AuthenticatedClient {
  config: OAuth2Config
  token: Token
  storage: Option[TokenStorage]
}

fn get_valid_token(client: AuthenticatedClient) -> Result[String, OAuth2Error]
```

### 3.4 複数フローのサポート

**実装予定:**
1. Authorization Code Flow（優先度: 高）
2. Authorization Code Flow + PKCE（優先度: 中）
3. Device Authorization Flow（優先度: 低）

## 4. テスト要件

### 4.1 ユニットテスト

**必要なテストケース:**
- Config作成と検証
- 認可URL生成の正確性
- トークンレスポンスのパース
- エラーレスポンスのパース
- state生成の一意性
- URLエンコーディング

### 4.2 統合テスト

**必要なテストシナリオ:**
- モックサーバーを使ったトークン取得フロー
- トークンリフレッシュフロー
- エラーハンドリング

### 4.3 E2Eテスト

**検証項目:**
- 実際のGoogle OAuth2エンドポイントとの通信
- 各種スコープでの認証
- トークンの失効

## 5. ドキュメント要件

### 5.1 README

**含めるべき内容:**
- クイックスタートガイド
- 基本的な使用例
- 認証フローの説明
- インストール方法

### 5.2 APIドキュメント

**含めるべき内容:**
- 全関数・型の説明
- 使用例
- エラーハンドリングのガイド

### 5.3 チュートリアル

**含めるべき内容:**
- Google Cloud Consoleでのクライアント作成
- 基本的な認証フロー実装
- トークンの保存と再利用
- エラーハンドリング

## 6. パフォーマンス要件

- トークンリフレッシュのレイテンシ: 500ms以内
- 認可URL生成: 10ms以内
- メモリ使用量: 最小限（設定とトークンのみ）

## 7. セキュリティ要件

### 必須:
- state パラメータによるCSRF対策
- HTTPSの強制（localhost除く）
- クライアントシークレットの安全な管理
- トークンの安全な保存

### 推奨:
- PKCEによる認可コード横取り対策
- トークンの暗号化保存
- リフレッシュトークンのローテーション

## 8. まとめ

### Phase 1（MVP）で実装すべき機能:
1. OAuth2Config型
2. 認可URL生成
3. 認可コードのパース
4. アクセストークン取得
5. 基本的なエラーハンドリング
6. state生成とCSRF対策

### Phase 2で実装すべき機能:
1. トークンリフレッシュ
2. トークン有効期限管理
3. トークン失効
4. スコープ定数定義

### Phase 3で実装すべき機能:
1. PKCE対応
2. トークンストレージインターフェース
3. 自動トークンリフレッシュ
4. Device Authorization Flow
