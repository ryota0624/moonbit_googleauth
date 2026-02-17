# Google OAuth2 認証実装調査ドキュメント

## 1. Google OAuth2認証の概要

### 1.1 基本フロー

Google OAuth2は、アプリケーションがユーザーの代わりにGoogle APIにアクセスするための標準的な認証プロトコルです。

**主要な実装ステップ:**
1. 認可パラメータの設定 - アクセス必要なリソース（スコープ）を識別
2. Googleサーバーへのリダイレクト - ユーザーを認可画面に送付
3. ユーザー同意の取得 - Googleが同意画面を表示
4. OAuth応答の処理 - 認可コードまたはエラーメッセージが返される
5. 認可コードをトークンに交換 - アクセス・リフレッシュトークン取得
6. 付与されたスコープの確認 - 実際に許可されたアクセス権を検証

### 1.2 必須認証情報

Google Cloud Consoleから以下を取得:
- **クライアントID** - アプリケーションの識別子
- **クライアントシークレット** - クライアント認証用（作成後のみ表示）
- **リダイレクトURI** - 認証後のコールバック先（複数指定可能）

### 1.3 主要APIエンドポイント

| エンドポイント | 用途 | メソッド |
|---|---|---|
| `https://accounts.google.com/o/oauth2/v2/auth` | 認可リクエスト | GET |
| `https://oauth2.googleapis.com/token` | トークン交換・リフレッシュ | POST |
| `https://oauth2.googleapis.com/revoke` | トークン失効 | POST |

### 1.4 トークンレスポンス形式

**トークン交換レスポンス（JSON）:**
```json
{
  "access_token": "ya29.xxx...",
  "expires_in": 3599,
  "refresh_token": "1//xxx...",
  "scope": "https://www.googleapis.com/auth/drive",
  "token_type": "Bearer"
}
```

**レスポンスフィールド:**
- `access_token` - APIリクエスト用トークン
- `expires_in` - 有効期限（秒）
- `refresh_token` - トークン更新用（offline時のみ）
- `scope` - 付与されたスコープ（スペース区切り）
- `token_type` - 常に「Bearer」

### 1.5 セキュリティ要件

- リダイレクトURIはHTTPS必須（localhostを除く）
- `state`パラメータでCSRF攻撃を防止
- オフラインアクセス時は`access_type=offline`設定
- リフレッシュトークンは安全に保管
- SSRF対策としてHTTPクライアントのリダイレクト自動追跡を無効化推奨

## 2. 参考ライブラリの分析

### 2.1 Rust oauth2-rs

**URL:** https://docs.rs/oauth2/latest/oauth2/

RustのOAuth2ライブラリは型安全性を重視した設計で、MoonBitの実装の参考になります。

#### 主要な型設計

**クライアント設定関連:**
- `ClientId` - クライアントID
- `ClientSecret` - クライアントシークレット
- `AuthUrl` - 認可エンドポイント
- `TokenUrl` - トークンエンドポイント
- `RedirectUrl` - リダイレクト先
- `BasicClient` - 統合管理構造体

**トークン関連:**
- `AccessToken` - リソースアクセス用
- `RefreshToken` - トークン更新用
- `AuthorizationCode` - 認可エンドポイント返却値

#### API設計パターン

ビルダーパターンで段階的に設定:
```rust
BasicClient::new(ClientId)
    .set_client_secret(ClientSecret)
    .set_auth_uri(AuthUrl)
    .set_token_uri(TokenUrl)
    .set_redirect_uri(RedirectUrl)
```

#### サポートするフロー

1. **Authorization Code Grant + PKCE** - `PkceCodeChallenge::new_random_sha256()`
2. **Implicit Grant** - `.use_implicit_flow()`
3. **Resource Owner Password** - `exchange_password()`
4. **Client Credentials** - `exchange_client_credentials()`
5. **Device Authorization Flow** - ブラウザレスデバイス向け

#### セキュリティ特性

- SSRF対策: HTTPクライアントでリダイレクト自動追跡を無効化
- タイミング攻撃対策: `timing-resistant-secret-traits`フラグ
- 型システムによる誤用防止

### 2.2 他言語のベストプラクティス

**共通の設計パターン:**
- 型安全な認証情報管理
- ビルダーパターンによる段階的設定
- エラー型の明示的な定義
- トークンの有効期限管理
- リフレッシュトークンの自動更新機能

## 3. MoonBitで利用可能なライブラリ

### 3.1 HTTPクライアント - mio

**URL:** https://github.com/oboard/mio

**特徴:**
- MoonBit向けの強力でモダンなHTTPネットワーキングライブラリ
- マルチバックエンドサポート（WebAssembly、JavaScript）
- 完全なHTTPメソッドサポート（GET、POST、PUT、DELETE等）
- JSONハンドリング組み込み
- ファイルダウンロード、ストリーム処理、バイナリデータサポート

### 3.2 JSON処理

MoonBitはJSON処理をビルトインでサポート:
- リテラルのオーバーロードによる便利な記法
- 数値、文字列、配列、マップリテラルを直接JSON化可能

### 3.3 moonbitlang/async

**特徴:**
- MoonBit公式の非同期プログラミングライブラリ
- ファイルシステム、プロセス、I/O、ソケット、HTTP機能をサポート
- 非同期HTTPリクエストに利用可能

## 4. 推奨実装アプローチ

### 4.1 設計方針

1. **型安全性の重視**
   - Rustのoauth2-rsを参考に、新しい型でクライアント認証情報を定義
   - 型システムを活用して誤用を防止

2. **段階的な実装**
   - まずAuthorization Code Flowを実装
   - その後、他のフローやPKCE対応を追加

3. **セキュリティファースト**
   - CSRF対策（state パラメータ）
   - HTTPSの強制（localhost除く）
   - シークレット情報の安全な管理

4. **HTTPライブラリの選択**
   - mioライブラリを採用
   - JSONハンドリングが組み込まれており、Google APIとの連携に最適

### 4.2 実装する主要コンポーネント

#### Config / Client設定
```moonbit
struct OAuth2Config {
  client_id: String
  client_secret: String
  auth_url: String
  token_url: String
  redirect_url: String
}
```

#### Token管理
```moonbit
struct TokenResponse {
  access_token: String
  expires_in: Int
  refresh_token: Option[String]
  scope: String
  token_type: String
}
```

#### Authorization Flow
- 認可URLの生成
- 認可コードの処理
- アクセストークンの取得
- リフレッシュトークンによる更新

### 4.3 外部依存関係

**必須:**
- `oboard/mio` - HTTPクライアント
- MoonBitビルトインJSON - レスポンスのパース

**推奨:**
- `moonbitlang/async` - 非同期処理が必要な場合

### 4.4 実装の優先順位

**Phase 1: 基本実装**
1. OAuth2Config型の定義
2. 認可URL生成機能
3. トークン取得・パース機能
4. 基本的なエラーハンドリング

**Phase 2: セキュリティ強化**
1. state パラメータによるCSRF対策
2. PKCEサポート
3. トークン有効期限の管理

**Phase 3: 高度な機能**
1. リフレッシュトークンの自動更新
2. トークンストレージ機能
3. スコープ管理
4. 複数の認証フロー対応

## 5. 参考資料

### 公式ドキュメント
- [Using OAuth 2.0 to Access Google APIs](https://developers.google.com/identity/protocols/oauth2)
- [Using OAuth 2.0 for Web Server Applications](https://developers.google.com/identity/protocols/oauth2/web-server)

### 参考実装
- [oauth2-rs (Rust)](https://docs.rs/oauth2/latest/oauth2/)
- [OAuth Libraries for Rust](https://oauth.net/code/rust/)

### MoonBit関連
- [MoonBit公式サイト](https://www.moonbitlang.com/)
- [mio - HTTP networking package](https://github.com/oboard/mio)
- [awesome-moonbit](https://github.com/moonbitlang/awesome-moonbit)
- [MoonBit Documentation](https://docs.moonbitlang.com/)

## 6. まとめ

MoonBitでGoogle OAuth2認証を実装するための基盤は整っています:
- mioライブラリによる強力なHTTPサポート
- ビルトインJSONサポート
- 型安全な言語設計

Rustのoauth2-rsを参考に、型安全性を重視した設計で段階的に実装していくことを推奨します。
