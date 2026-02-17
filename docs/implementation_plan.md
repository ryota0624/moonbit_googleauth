# Google OAuth2認証ライブラリ 実装計画

## 1. 実装の全体方針

### 1.1 段階的なアプローチ

**原則:**
- 動作する最小限の実装（MVP）を優先
- 各フェーズで動作検証を実施
- 型安全性とセキュリティを最優先
- テスト駆動開発（TDD）を推奨

### 1.2 依存関係の管理

**Phase 1での外部依存:**
- `oboard/mio` - HTTPクライアント
- MoonBitビルトインJSON - レスポンスパース

**Phase 2以降での検討:**
- 暗号学的乱数生成ライブラリ（state生成用）
- Base64エンコーディングライブラリ（PKCE用）

## 2. Phase 1: MVP実装（基本的な認証フロー）

**目標:** Google OAuth2の基本的な認証フローを動作させる

**推定工数:** 3-5日

### 2.1 ファイル構成

```
googleauth/
├── config.mbt          # OAuth2Config型と設定管理
├── types.mbt           # 共通の型定義
├── errors.mbt          # エラー型定義
├── auth_url.mbt        # 認可URL生成
├── token.mbt           # トークン取得・管理
├── utils.mbt           # ユーティリティ関数
└── http_client.mbt     # HTTPクライアントラッパー
```

### 2.2 実装順序

#### Step 1: 基本型定義（1日目）

**実装ファイル:** `types.mbt`, `errors.mbt`

**実装内容:**
1. OAuth2Config型
```moonbit
struct OAuth2Config {
  client_id: String
  client_secret: String
  auth_url: String
  token_url: String
  redirect_url: String
  scopes: Array[String]
}
```

2. TokenResponse型
```moonbit
struct TokenResponse {
  access_token: String
  expires_in: Int
  refresh_token: Option[String]
  scope: String
  token_type: String
}
```

3. Token型（有効期限管理用）
```moonbit
struct Token {
  access_token: String
  refresh_token: Option[String]
  expires_at: Int64
  scope: String
  token_type: String
}
```

4. OAuth2Error型
```moonbit
enum OAuth2Error {
  InvalidRequest(String)
  UnauthorizedClient(String)
  AccessDenied(String)
  InvalidScope(String)
  InvalidGrant(String)
  NetworkError(String)
  ParseError(String)
  StateVerificationFailed(String)
  ServerError(String)
}
```

**テスト:**
- Config作成のユニットテスト
- エラー型の基本テスト

**完了条件:**
- 全型定義がコンパイル可能
- 基本的なユニットテストが通過

#### Step 2: ユーティリティ関数（1日目）

**実装ファイル:** `utils.mbt`

**実装内容:**
1. URLエンコーディング
```moonbit
fn url_encode(value: String) -> String
```

2. クエリ文字列生成
```moonbit
fn build_query_string(params: Map[String, String]) -> String
```

3. state生成（シンプル版）
```moonbit
fn generate_state() -> String
// Phase 1では簡易的な実装（ランダム文字列生成）
// Phase 2で暗号学的に安全な実装に改善
```

4. デフォルトURL定数
```moonbit
let default_auth_url = "https://accounts.google.com/o/oauth2/v2/auth"
let default_token_url = "https://oauth2.googleapis.com/token"
let default_revoke_url = "https://oauth2.googleapis.com/revoke"
```

**テスト:**
- URLエンコーディングのテスト（特殊文字を含む）
- クエリ文字列生成のテスト
- state生成の一意性テスト

**完了条件:**
- 全ユーティリティ関数が正しく動作
- エッジケースのテストが通過

#### Step 3: Config管理（1日目）

**実装ファイル:** `config.mbt`

**実装内容:**
1. Configビルダー
```moonbit
fn new_config(
  client_id: String,
  client_secret: String,
  redirect_url: String
) -> OAuth2Config

fn with_scopes(config: OAuth2Config, scopes: Array[String]) -> OAuth2Config

fn with_custom_urls(
  config: OAuth2Config,
  auth_url: String,
  token_url: String
) -> OAuth2Config
```

2. Config検証
```moonbit
fn validate_config(config: OAuth2Config) -> Result[Unit, OAuth2Error]
// - client_id, client_secretが空でないか
// - URLがHTTPSか（localhost除く）
// - redirect_urlが有効なURIか
```

**テスト:**
- Config作成のテスト
- スコープ追加のテスト
- 検証ロジックのテスト（正常系・異常系）

**完了条件:**
- Config管理APIが使いやすく動作
- 不正な設定を適切に検出

#### Step 4: 認可URL生成（2日目）

**実装ファイル:** `auth_url.mbt`

**実装内容:**
1. 認可URLオプション型
```moonbit
struct AuthUrlOptions {
  state: String
  access_type: Option[String]      // "offline" でリフレッシュトークン取得
  prompt: Option[String]           // "consent" で常に同意画面表示
  include_granted_scopes: Bool     // 増分認可
}
```

2. 認可URL生成関数
```moonbit
fn generate_auth_url(
  config: OAuth2Config,
  options: AuthUrlOptions
) -> String
```

**生成例:**
```
https://accounts.google.com/o/oauth2/v2/auth?
  client_id={client_id}&
  redirect_uri={redirect_uri}&
  response_type=code&
  scope={scopes}&
  state={state}&
  access_type=offline
```

**テスト:**
- 必須パラメータが含まれているか
- オプションパラメータが正しく追加されるか
- URLエンコーディングが正しいか
- スコープがスペース区切りで連結されているか

**完了条件:**
- 生成されたURLがGoogle OAuth2仕様に準拠
- 全テストが通過

#### Step 5: 認可コードのパース（2日目）

**実装ファイル:** `auth_url.mbt`

**実装内容:**
1. リダイレクトレスポンスのパース
```moonbit
struct AuthorizationResponse {
  code: Option[String]
  state: String
  error: Option[String]
  error_description: Option[String]
}

fn parse_authorization_response(
  url: String
) -> Result[AuthorizationResponse, OAuth2Error]
```

2. state検証
```moonbit
fn verify_state(
  response: AuthorizationResponse,
  expected_state: String
) -> Result[String, OAuth2Error]
// 成功時は認可コードを返す
```

**テスト:**
- 正常なレスポンスのパース
- エラーレスポンスのパース
- state検証（一致・不一致）
- 不正なURLフォーマットのハンドリング

**完了条件:**
- 全種類のレスポンスを正しくパース
- CSRF対策が有効に機能

#### Step 6: HTTPクライアントラッパー（3日目）

**実装ファイル:** `http_client.mbt`

**実装内容:**
1. mioラッパー
```moonbit
fn post_form(
  url: String,
  params: Map[String, String]
) -> Result[String, OAuth2Error]
// Content-Type: application/x-www-form-urlencoded
// レスポンスボディを文字列で返す
```

2. JSONパース（MoonBitビルトイン使用）
```moonbit
fn parse_token_response(
  json: String
) -> Result[TokenResponse, OAuth2Error]

fn parse_error_response(
  json: String
) -> OAuth2Error
```

**テスト:**
- モックHTTPサーバーでのテスト
- 成功レスポンスのパース
- エラーレスポンスのパース
- ネットワークエラーのハンドリング

**完了条件:**
- HTTPリクエストが正しく送信される
- レスポンスが正しくパースされる

#### Step 7: トークン取得（3-4日目）

**実装ファイル:** `token.mbt`

**実装内容:**
1. 認可コードからトークン取得
```moonbit
fn exchange_code_for_token(
  config: OAuth2Config,
  code: String
) -> Result[TokenResponse, OAuth2Error]
```

**リクエストパラメータ:**
- code: 認可コード
- client_id: クライアントID
- client_secret: クライアントシークレット
- redirect_uri: リダイレクトURI
- grant_type: "authorization_code"

2. TokenResponseからTokenへの変換
```moonbit
fn token_from_response(
  response: TokenResponse
) -> Token
// expires_atを現在時刻 + expires_inで計算
```

**テスト:**
- モックサーバーでの完全なフロー
- エラーレスポンスのハンドリング
- Token変換の正確性

**完了条件:**
- 実際のGoogle APIとの疎通確認（手動テスト）
- 全自動テストが通過

#### Step 8: 統合とE2Eテスト（4-5日目）

**実装内容:**
1. サンプルアプリケーション（`cmd/main/main.mbt`）
```moonbit
fn main {
  // 1. Config作成
  let config = new_config(
    client_id,
    client_secret,
    "http://localhost:8080/callback"
  )
  |> with_scopes(["https://www.googleapis.com/auth/userinfo.email"])

  // 2. 認可URL生成
  let state = generate_state()
  let auth_url = generate_auth_url(config, AuthUrlOptions{
    state,
    access_type: Some("offline"),
    prompt: None,
    include_granted_scopes: false
  })

  println("Open this URL in browser:")
  println(auth_url)

  // 3. ユーザーがリダイレクトされたURLを入力
  println("\nEnter the redirect URL:")
  let redirect_url = read_line()

  // 4. 認可コード抽出
  let response = parse_authorization_response(redirect_url)?
  let code = verify_state(response, state)?

  // 5. トークン取得
  let token_response = exchange_code_for_token(config, code)?
  let token = token_from_response(token_response)

  println("Access token obtained!")
  println("Token: " + token.access_token)
}
```

2. 手動E2Eテスト手順書
3. 既知の問題とトラブルシューティングドキュメント

**テスト:**
- 実際のGoogle OAuth2を使った完全なフロー
- 各種エラーシナリオの検証

**完了条件:**
- サンプルアプリが正しく動作
- ドキュメントが整備されている

### 2.3 Phase 1の成果物

- 動作する基本的なOAuth2クライアント
- ユニットテストスイート
- サンプルアプリケーション
- 基本ドキュメント

### 2.4 Phase 1の制限事項

- トークンリフレッシュ未実装
- トークン永続化未実装
- PKCE未対応
- state生成が暗号学的に安全でない可能性

## 3. Phase 2: トークン管理強化

**目標:** トークンの完全なライフサイクル管理

**推定工数:** 2-3日

### 3.1 実装項目

#### Step 1: トークンリフレッシュ（1日目）

**実装ファイル:** `token.mbt`

**実装内容:**
```moonbit
fn refresh_access_token(
  config: OAuth2Config,
  refresh_token: String
) -> Result[TokenResponse, OAuth2Error]
```

**テスト:**
- リフレッシュフロー
- エラーハンドリング

#### Step 2: トークン有効期限管理（1日目）

**実装ファイル:** `token.mbt`

**実装内容:**
```moonbit
fn is_expired(token: Token) -> Bool

fn needs_refresh(token: Token, threshold: Float) -> Bool
// threshold: 期限の何%で更新するか（デフォルト0.9）

fn get_valid_token(
  config: OAuth2Config,
  token: Token
) -> Result[Token, OAuth2Error]
// 必要に応じて自動リフレッシュ
```

**テスト:**
- 有効期限判定
- 自動リフレッシュロジック

#### Step 3: トークン失効（2日目）

**実装ファイル:** `token.mbt`

**実装内容:**
```moonbit
fn revoke_token(token: String) -> Result[Unit, OAuth2Error]
```

**テスト:**
- 失効リクエスト
- エラーハンドリング

#### Step 4: スコープ定数定義（2日目）

**実装ファイル:** `scopes.mbt`

**実装内容:**
```moonbit
// Google Drive
let scope_drive_readonly = "https://www.googleapis.com/auth/drive.readonly"
let scope_drive = "https://www.googleapis.com/auth/drive"

// Gmail
let scope_gmail_readonly = "https://www.googleapis.com/auth/gmail.readonly"
let scope_gmail_send = "https://www.googleapis.com/auth/gmail.send"

// 他の一般的なスコープ...
```

#### Step 5: 統合テストとドキュメント更新（3日目）

**実装内容:**
- リフレッシュトークンを使ったサンプル更新
- APIドキュメント更新
- チュートリアル追加

### 3.2 Phase 2の成果物

- 完全なトークンライフサイクル管理
- スコープ定数ライブラリ
- 更新されたドキュメント

## 4. Phase 3: セキュリティとストレージ

**目標:** プロダクション環境での利用に必要な機能

**推定工数:** 3-4日

### 4.1 実装項目

#### Step 1: PKCE対応（1-2日目）

**実装ファイル:** `pkce.mbt`

**実装内容:**
```moonbit
struct PkceChallenge {
  verifier: String
  challenge: String
  method: String  // "S256" or "plain"
}

fn generate_pkce_challenge() -> PkceChallenge
```

**認可URL生成への追加:**
- code_challenge パラメータ
- code_challenge_method パラメータ

**トークン交換への追加:**
- code_verifier パラメータ

**テスト:**
- PKCE生成と検証
- 完全なPKCEフロー

#### Step 2: トークンストレージインターフェース（2-3日目）

**実装ファイル:** `storage.mbt`

**実装内容:**
```moonbit
trait TokenStorage {
  fn save(token: Token) -> Result[Unit, StorageError]
  fn load() -> Result[Option[Token], StorageError]
  fn delete() -> Result[Unit, StorageError]
}

// ファイルベースの実装例
struct FileTokenStorage {
  path: String
}

impl TokenStorage for FileTokenStorage {
  // 実装...
}
```

**テスト:**
- 保存・読み込み・削除
- ファイルが存在しない場合のハンドリング

#### Step 3: 暗号学的に安全なstate生成（3日目）

**実装ファイル:** `utils.mbt`

**実装内容:**
```moonbit
fn generate_secure_state() -> String
// プラットフォーム依存の安全な乱数生成を使用
```

#### Step 4: AuthenticatedClient（4日目）

**実装ファイル:** `client.mbt`

**実装内容:**
```moonbit
struct AuthenticatedClient {
  config: OAuth2Config
  token: Token
  storage: Option[TokenStorage]
}

fn new_authenticated_client(
  config: OAuth2Config,
  token: Token,
  storage: Option[TokenStorage]
) -> AuthenticatedClient

fn get_access_token(
  client: AuthenticatedClient
) -> Result[String, OAuth2Error]
// 自動リフレッシュとストレージ更新

fn save_token(
  client: AuthenticatedClient
) -> Result[Unit, OAuth2Error]

fn load_token(
  config: OAuth2Config,
  storage: TokenStorage
) -> Result[Option[AuthenticatedClient], OAuth2Error]
```

**テスト:**
- 自動リフレッシュ機能
- ストレージ統合

### 4.2 Phase 3の成果物

- PKCE対応
- トークンストレージシステム
- 高レベルなAuthenticatedClient API
- プロダクション環境用のドキュメント

## 5. 継続的改善（Phase 4以降）

### 5.1 追加機能候補

- Device Authorization Flow
- Service Account認証
- ID Token検証
- トークン暗号化保存
- より高度なエラーリトライロジック

### 5.2 パフォーマンス最適化

- HTTP接続のプーリング
- レスポンスキャッシング
- 並行リクエスト処理

### 5.3 開発者体験向上

- より詳細なエラーメッセージ
- デバッグログ機能
- 設定バリデーションの改善
- より多くのサンプルコード

## 6. 実装のマイルストーン

### Milestone 1: MVP（Phase 1完了）
- 期限: 実装開始から1週間
- デリバリブル: 基本的な認証フローが動作

### Milestone 2: トークン管理（Phase 2完了）
- 期限: Milestone 1から3日後
- デリバリブル: トークンリフレッシュと完全な管理機能

### Milestone 3: プロダクション対応（Phase 3完了）
- 期限: Milestone 2から1週間後
- デリバリブル: PKCEとストレージ機能

### Milestone 4: 1.0リリース
- 期限: Milestone 3から1週間後
- デリバリブル: 完全なドキュメント、テスト、サンプル

## 7. リスクと軽減策

### リスク1: mioライブラリの制限

**リスク:** mioが必要な機能をサポートしていない可能性

**軽減策:**
- 早期にmioの機能を検証
- 必要に応じて直接HTTPリクエストを実装
- moonbitlang/asyncを代替として検討

### リスク2: 暗号学的乱数生成

**リスク:** MoonBitに適切な乱数生成機能がない可能性

**軽減策:**
- Phase 1では簡易実装で進める
- Phase 3までに解決策を調査
- 外部ライブラリの使用を検討

### リスク3: Google API仕様変更

**リスク:** Google OAuth2の仕様が変更される可能性

**軽減策:**
- 公式ドキュメントを定期的にチェック
- バージョニングとchangelogの徹底
- 柔軟な設計（カスタムエンドポイント対応など）

## 8. まとめ

この実装計画により、約2-3週間で完全なGoogle OAuth2認証ライブラリを実装できます。

**重要な原則:**
- 段階的な実装
- 各フェーズでの動作検証
- セキュリティファースト
- ドキュメントの同時作成

**次のステップ:**
1. プロジェクトセットアップ
2. 依存関係（mio）の追加
3. Phase 1 Step 1の実装開始
