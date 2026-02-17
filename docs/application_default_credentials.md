# Application Default Credentials (ADC) とメタデータサーバー認証

## 1. 概要

プロダクション環境でのGoogle Cloud認証には、以下の3つの方法が一般的です：

1. **Application Default Credentials (ADC)** - 環境変数からの自動検出 ⭐ **推奨**
2. **Metadata Server** - Google Cloud環境での自動認証 ⭐ **推奨**
3. **Explicit Service Account Key** - private keyを明示的に指定

Googleの公式SDKは、この順序で自動的に認証方法を試行します。

## 2. Application Default Credentials (ADC)

### 2.1 概要

**Application Default Credentials**は、環境変数 `GOOGLE_APPLICATION_CREDENTIALS` からService Accountキーファイルのパスを読み取る標準的な方法です。

**メリット:**
- ✅ Google Cloud公式の標準方式
- ✅ 環境ごとに異なる認証情報を使い分け可能
- ✅ コードに認証情報をハードコードしない
- ✅ 開発環境と本番環境で同じコードが動作

**フロー:**
```
1. 環境変数 GOOGLE_APPLICATION_CREDENTIALS を確認
2. ファイルパスが設定されている場合、そのJSONファイルを読み込み
3. Service Account認証を実行
4. アクセストークンを取得
```

### 2.2 実装計画

#### 環境変数からの読み取り

```moonbit
// lib/service_account/adc.mbt

///| Application Default Credentials from environment variable
pub fn load_credentials_from_env() -> Result[ServiceAccountCredentials, AdcError] {
  // 1. 環境変数を確認
  let key_path = match @os.get_env("GOOGLE_APPLICATION_CREDENTIALS") {
    Some(path) => path
    None => return Err(AdcError::EnvNotSet)
  }

  // 2. ファイルを読み込み
  let key_content = @fs.read_to_string(key_path)
    .map_err(|e| AdcError::FileReadError(e))?

  // 3. JSONをパース
  parse_service_account_key(key_content)
}
```

#### Service Account JSONキーのパース

```moonbit
///| Service Account Key File structure
pub struct ServiceAccountCredentials {
  type_ : String           // "service_account"
  project_id : String
  private_key_id : String
  private_key : String     // PEM format
  client_email : String
  client_id : String
  auth_uri : String
  token_uri : String
  auth_provider_x509_cert_url : String
  client_x509_cert_url : String
}

///| Parse Service Account key JSON file
pub fn parse_service_account_key(
  json : String
) -> Result[ServiceAccountCredentials, AdcError] {
  let parsed = @json.parse(json)
    .map_err(|e| AdcError::JsonParseError(e))?

  // JSONから各フィールドを抽出
  let type_ = parsed["type"].as_string()
    .ok_or(AdcError::MissingField("type"))?

  let project_id = parsed["project_id"].as_string()
    .ok_or(AdcError::MissingField("project_id"))?

  let private_key = parsed["private_key"].as_string()
    .ok_or(AdcError::MissingField("private_key"))?

  let client_email = parsed["client_email"].as_string()
    .ok_or(AdcError::MissingField("client_email"))?

  // ... 他のフィールド

  Ok({
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
```

#### エラー型定義

```moonbit
///| ADC Error types
pub enum AdcError {
  EnvNotSet                          // 環境変数が設定されていない
  FileReadError(String)              // ファイル読み込みエラー
  JsonParseError(String)             // JSONパースエラー
  MissingField(String)               // 必須フィールドが欠落
  InvalidCredentials(String)         // 認証情報が不正
}

pub fn AdcError::to_string(self : AdcError) -> String {
  match self {
    EnvNotSet =>
      "GOOGLE_APPLICATION_CREDENTIALS environment variable is not set"
    FileReadError(msg) =>
      "Failed to read credentials file: \{msg}"
    JsonParseError(msg) =>
      "Failed to parse JSON: \{msg}"
    MissingField(field) =>
      "Missing required field in credentials: \{field}"
    InvalidCredentials(msg) =>
      "Invalid credentials: \{msg}"
  }
}
```

### 2.3 使用例

```moonbit
// 環境変数から自動的にロード
let credentials = @googleauth.load_credentials_from_env()?

let auth = @googleauth.ServiceAccountAuth::from_credentials(
  credentials,
  ["https://www.googleapis.com/auth/cloud-platform"]
)

let token = auth.get_access_token().await?
println("Access Token: \{token.access_token()}")
```

**環境変数の設定:**
```bash
# 開発環境
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/dev-service-account.json"

# 本番環境
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/prod-service-account.json"
```

## 3. Metadata Server認証

### 3.1 概要

**Metadata Server**は、Google Cloud環境（GCE、GKE、Cloud Run、Cloud Functions等）で自動的に利用可能な認証方法です。

**メリット:**
- ✅ private keyの管理が不要
- ✅ 最も安全（keyファイルの流出リスクなし）
- ✅ Google Cloud環境で自動的に動作
- ✅ トークンローテーションが自動

**対応環境:**
- ✅ Google Compute Engine (GCE)
- ✅ Google Kubernetes Engine (GKE)
- ✅ Cloud Run
- ✅ Cloud Functions
- ✅ App Engine

**フロー:**
```
1. メタデータサーバーのエンドポイントにリクエスト
   GET http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
   Header: Metadata-Flavor: Google

2. レスポンスでアクセストークンを取得
   {
     "access_token": "ya29.xxx...",
     "expires_in": 3599,
     "token_type": "Bearer"
   }

3. トークンを使用
```

### 3.2 実装計画

#### メタデータサーバークライアント

```moonbit
// lib/service_account/metadata.mbt

///| Metadata server configuration
pub struct MetadataServerConfig {
  base_url : String
  service_account : String  // "default" or specific email
}

///| Default metadata server config
pub fn MetadataServerConfig::default() -> MetadataServerConfig {
  {
    base_url: "http://metadata.google.internal",
    service_account: "default",
  }
}

///| Metadata server token response
pub struct MetadataTokenResponse {
  access_token : String
  expires_in : Int
  token_type : String
}
```

#### トークン取得

```moonbit
///| Get access token from metadata server
pub fn get_token_from_metadata_server(
  config : MetadataServerConfig,
  scopes : Array[String]
) -> @http.Future[MetadataTokenResponse] {
  // エンドポイントURL構築
  let url = "\{config.base_url}/computeMetadata/v1/instance/service-accounts/\{config.service_account}/token"

  // スコープがある場合はクエリパラメータに追加
  let url_with_scopes = if scopes.length() > 0 {
    let scope_param = scopes.join(",")
    "\{url}?scopes=\{@url.encode(scope_param)}"
  } else {
    url
  }

  // HTTPリクエスト
  let headers = @http.Headers::new()
    .set("Metadata-Flavor", "Google")

  let request = @http.Request::new(url_with_scopes)
    .set_method(@http.Method::GET)
    .set_headers(headers)

  let response = @http.fetch(request).await?

  // ステータスコード確認
  if response.status() != 200 {
    return Err(MetadataError::HttpError(
      response.status(),
      response.body()
    ))
  }

  // レスポンスをパース
  parse_metadata_token_response(response.body())
}

///| Parse metadata server token response
fn parse_metadata_token_response(
  json : String
) -> Result[MetadataTokenResponse, MetadataError] {
  let parsed = @json.parse(json)
    .map_err(|e| MetadataError::JsonParseError(e))?

  let access_token = parsed["access_token"].as_string()
    .ok_or(MetadataError::MissingField("access_token"))?

  let expires_in = parsed["expires_in"].as_int()
    .ok_or(MetadataError::MissingField("expires_in"))?

  let token_type = parsed["token_type"].as_string()
    .ok_or(MetadataError::MissingField("token_type"))?

  Ok({
    access_token,
    expires_in,
    token_type,
  })
}
```

#### メタデータサーバー可用性チェック

```moonbit
///| Check if running in Google Cloud environment
pub fn is_metadata_server_available() -> @http.Future[Bool] {
  let config = MetadataServerConfig::default()
  let url = "\{config.base_url}/computeMetadata/v1/"

  let headers = @http.Headers::new()
    .set("Metadata-Flavor", "Google")

  let request = @http.Request::new(url)
    .set_method(@http.Method::GET)
    .set_headers(headers)
    .set_timeout(1000)  // 1秒タイムアウト

  match @http.fetch(request).await {
    Ok(response) => Ok(response.status() == 200)
    Err(_) => Ok(false)  // ネットワークエラー = メタデータサーバーなし
  }
}
```

#### エラー型定義

```moonbit
///| Metadata server error types
pub enum MetadataError {
  NotAvailable                       // メタデータサーバーが利用不可
  HttpError(Int, String)             // HTTPエラー（ステータスコード、ボディ）
  JsonParseError(String)             // JSONパースエラー
  MissingField(String)               // 必須フィールド欠落
  NetworkError(String)               // ネットワークエラー
}
```

### 3.3 使用例

```moonbit
// メタデータサーバーからトークン取得
let config = @googleauth.MetadataServerConfig::default()
let scopes = ["https://www.googleapis.com/auth/cloud-platform"]

let token = @googleauth.get_token_from_metadata_server(config, scopes).await?
println("Access Token: \{token.access_token}")
println("Expires in: \{token.expires_in} seconds")
```

**Cloud Run / GKEでの使用:**
```moonbit
// コードは同じ - 環境が自動検出される
let token = @googleauth.get_token_from_metadata_server(
  @googleauth.MetadataServerConfig::default(),
  ["https://www.googleapis.com/auth/cloud-platform"]
).await?
```

## 4. 統合: 自動認証検出

### 4.1 概要

Google Cloud公式SDKと同様に、複数の認証方法を自動的に試行する統合APIを提供します。

**試行順序:**
1. **明示的な認証情報** - 直接指定された場合
2. **環境変数 (ADC)** - `GOOGLE_APPLICATION_CREDENTIALS`
3. **メタデータサーバー** - Google Cloud環境
4. **エラー** - すべて失敗

### 4.2 実装計画

#### 統合認証クライアント

```moonbit
// lib/google_auth_client.mbt

///| Google authentication client with automatic credential detection
pub struct GoogleAuthClient {
  credentials : Option[AuthCredentials]
  scopes : Array[String]
}

///| Authentication credentials types
pub enum AuthCredentials {
  ServiceAccount(ServiceAccountCredentials)
  ClientCredentials(String, String)  // client_id, client_secret
  MetadataServer
}

///| Create a new GoogleAuthClient
pub fn GoogleAuthClient::new(scopes : Array[String]) -> GoogleAuthClient {
  {
    credentials: None,
    scopes,
  }
}

///| Create with explicit credentials
pub fn GoogleAuthClient::with_credentials(
  credentials : AuthCredentials,
  scopes : Array[String]
) -> GoogleAuthClient {
  {
    credentials: Some(credentials),
    scopes,
  }
}
```

#### 自動認証検出

```moonbit
///| Get access token with automatic credential detection
pub fn GoogleAuthClient::get_access_token(
  self : GoogleAuthClient
) -> @http.Future[String] {
  match self.credentials {
    // 1. 明示的な認証情報が指定されている場合
    Some(creds) => self.get_token_from_credentials(creds).await

    // 2. 自動検出
    None => self.auto_detect_and_authenticate().await
  }
}

///| Automatic credential detection
fn GoogleAuthClient::auto_detect_and_authenticate(
  self : GoogleAuthClient
) -> @http.Future[String] {
  // Step 1: Application Default Credentials (環境変数)
  match load_credentials_from_env() {
    Ok(creds) => {
      println("[Auth] Using Application Default Credentials")
      return self.authenticate_with_service_account(creds).await
    }
    Err(_) => {
      // 環境変数が設定されていない、続行
    }
  }

  // Step 2: Metadata Server (Google Cloud環境)
  if is_metadata_server_available().await? {
    println("[Auth] Using Metadata Server")
    let token = get_token_from_metadata_server(
      MetadataServerConfig::default(),
      self.scopes
    ).await?
    return Ok(token.access_token)
  }

  // Step 3: すべて失敗
  Err(AuthError::NoCredentialsFound(
    "No valid credentials found. Please set GOOGLE_APPLICATION_CREDENTIALS or run in Google Cloud environment."
  ))
}
```

#### 認証方法ごとの処理

```moonbit
///| Authenticate with service account
fn GoogleAuthClient::authenticate_with_service_account(
  self : GoogleAuthClient,
  creds : ServiceAccountCredentials
) -> @http.Future[String] {
  let auth = ServiceAccountAuth::from_credentials(creds, self.scopes)
  let token = auth.get_access_token().await?
  Ok(token.access_token().to_string())
}

///| Authenticate with client credentials
fn GoogleAuthClient::authenticate_with_client_credentials(
  self : GoogleAuthClient,
  client_id : String,
  client_secret : String
) -> @http.Future[String] {
  let request = @oauth2.ClientCredentialsRequest::new(
    @googleauth.google_token_url,
    @oauth2.ClientId::new(client_id),
    @oauth2.ClientSecret::new(client_secret),
    self.scopes.map(@oauth2.Scope::new),
  )

  let http_client = @oauth2.OAuth2HttpClient::new()
  let token = request.execute(http_client).await?
  Ok(token.access_token().to_string())
}

///| Get token from specific credentials
fn GoogleAuthClient::get_token_from_credentials(
  self : GoogleAuthClient,
  creds : AuthCredentials
) -> @http.Future[String] {
  match creds {
    ServiceAccount(sa_creds) =>
      self.authenticate_with_service_account(sa_creds).await

    ClientCredentials(id, secret) =>
      self.authenticate_with_client_credentials(id, secret).await

    MetadataServer => {
      let token = get_token_from_metadata_server(
        MetadataServerConfig::default(),
        self.scopes
      ).await?
      Ok(token.access_token)
    }
  }
}
```

### 4.3 使用例

#### 自動検出（推奨）

```moonbit
// 最もシンプル - 自動的に最適な認証方法を選択
let client = @googleauth.GoogleAuthClient::new([
  "https://www.googleapis.com/auth/cloud-platform"
])

let token = client.get_access_token().await?
println("Access Token: \{token}")
```

**動作:**
- 開発環境: `GOOGLE_APPLICATION_CREDENTIALS` から読み込み
- Cloud Run: メタデータサーバーから自動取得
- GKE: メタデータサーバーから自動取得

#### 明示的な認証情報

```moonbit
// Service Accountを明示的に指定
let creds = @googleauth.load_credentials_from_env()?
let client = @googleauth.GoogleAuthClient::with_credentials(
  @googleauth.AuthCredentials::ServiceAccount(creds),
  ["https://www.googleapis.com/auth/cloud-platform"]
)

let token = client.get_access_token().await?
```

## 5. 実装優先度と工数

### 5.1 実装項目

| 項目 | 優先度 | 工数 | 依存 |
|---|---|---|---|
| ADC環境変数読み取り | **高** | 1-2時間 | なし |
| Service Account JSONパース | **高** | 2-3時間 | なし |
| メタデータサーバークライアント | **高** | 2-3時間 | HTTP |
| メタデータサーバー可用性チェック | 高 | 1時間 | HTTP |
| 自動認証検出 | 高 | 2-3時間 | 上記すべて |
| 統合GoogleAuthClient | 中 | 2-3時間 | 上記すべて |

**合計工数:** 10-15時間（1.5-2日）

### 5.2 実装順序

**Phase 1: 基本機能（4-6時間）**
1. ADC環境変数読み取り
2. Service Account JSONパース
3. ユニットテスト

**Phase 2: メタデータサーバー（3-4時間）**
1. メタデータサーバークライアント
2. 可用性チェック
3. 統合テスト（GCE/Cloud Runでの動作確認）

**Phase 3: 自動検出（3-5時間）**
1. 自動認証検出ロジック
2. GoogleAuthClient統合
3. E2Eテスト（複数環境）

## 6. テスト戦略

### 6.1 ユニットテスト

```moonbit
// ADCテスト
test "load_credentials_from_env with valid path" {
  @os.set_env("GOOGLE_APPLICATION_CREDENTIALS", "/path/to/test-key.json")
  let result = load_credentials_from_env()
  assert_true(result.is_ok())
}

test "load_credentials_from_env without env var" {
  @os.unset_env("GOOGLE_APPLICATION_CREDENTIALS")
  let result = load_credentials_from_env()
  assert_true(result.is_err())
}

// JSONパーステスト
test "parse_service_account_key with valid JSON" {
  let json = """
  {
    "type": "service_account",
    "project_id": "test-project",
    "private_key": "-----BEGIN PRIVATE KEY-----...",
    "client_email": "test@test-project.iam.gserviceaccount.com"
  }
  """
  let result = parse_service_account_key(json)
  assert_true(result.is_ok())
}
```

### 6.2 統合テスト

**ローカル環境:**
```bash
# ADCテスト
export GOOGLE_APPLICATION_CREDENTIALS="./test-service-account.json"
moon test --integration
```

**Cloud Run環境:**
```bash
# メタデータサーバーテスト
gcloud run deploy test-app --source . --region us-central1
# アプリ内でメタデータサーバーからトークン取得を確認
```

### 6.3 E2Eテスト

**複数環境での動作確認:**
1. ローカル開発環境（ADC）
2. GCE（メタデータサーバー）
3. Cloud Run（メタデータサーバー）
4. GKE（メタデータサーバー）

## 7. まとめ

### 7.1 認証方法の完全対応

| 認証方法 | 実装状況 | 優先度 | 工数 |
|---|---|---|---|
| Authorization Code Flow | ✅ 完了 | 高 | 0時間 |
| Client Credentials Flow | ✅ 完了 | 高 | 2-3時間（ラッパーのみ） |
| Service Account (JWT) | ❌ 未実装 | 中 | 4-6時間 |
| **ADC (環境変数)** | ❌ **未実装** | **高** | **3-5時間** |
| **Metadata Server** | ❌ **未実装** | **高** | **3-4時間** |
| **自動検出** | ❌ **未実装** | **高** | **3-5時間** |

### 7.2 更新された実装計画

#### Phase 1.5: Server-to-Server認証（見直し）

**推定工数: 1.5-2.5日**（当初0.5-1日から増加）

1. **Client Credentials Flow ラッパー**（2-3時間）
   - 既存ライブラリ活用

2. **Application Default Credentials**（3-5時間）⭐ **NEW**
   - 環境変数読み取り
   - JSONキーパース
   - ユニットテスト

3. **Metadata Server**（3-4時間）⭐ **NEW**
   - HTTPクライアント実装
   - 可用性チェック
   - 統合テスト

4. **自動認証検出**（3-5時間）⭐ **NEW**
   - GoogleAuthClient
   - 複数環境でのE2E

5. **Service Account JWT**（4-6時間）- 条件付き
   - RSA署名ライブラリ調査
   - JWT生成・署名

**合計: 12-20時間（1.5-2.5日）**

### 7.3 推奨実装順序

**優先度1（必須）:**
1. ADC環境変数読み取り
2. メタデータサーバー
3. 自動検出

**優先度2（推奨）:**
4. Client Credentials Flowラッパー
5. 統合GoogleAuthClient

**優先度3（オプション）:**
6. Service Account JWT（RSA署名ライブラリ次第）

---

**結論:** ADCとメタデータサーバー対応は**プロダクション環境では必須**です。実装計画に追加し、優先度を高く設定します。
