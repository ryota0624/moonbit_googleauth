# Server-to-Server認証の実装計画

## 1. 概要

Google APIでのServer-to-Server認証には複数の方法があります：

1. **Client Credentials Flow** - 標準OAuth2フロー
2. **Application Default Credentials (ADC)** - 環境変数からの自動検出 ⭐ **推奨**
3. **Metadata Server** - Google Cloud環境での自動認証 ⭐ **推奨**
4. **Service Account JWT** - Google特有のJWT-based認証

**重要:** ADCとMetadata Serverの詳細は [application_default_credentials.md](application_default_credentials.md) を参照してください。

## 2. 既存ライブラリの対応状況

### 2.1 Client Credentials Flow ✅

**`ryota0624/oauth2` で既に実装済み**

```moonbit
// 既存ライブラリの使用例
let token_url = @oauth2.TokenUrl::new("https://oauth2.googleapis.com/token")
let client_id = @oauth2.ClientId::new("your-client-id")
let client_secret = @oauth2.ClientSecret::new("your-client-secret")
let scopes = [
  @oauth2.Scope::new("https://www.googleapis.com/auth/cloud-platform")
]

let request = @oauth2.ClientCredentialsRequest::new(
  token_url,
  client_id,
  client_secret,
  scopes,
)

let http_client = @oauth2.OAuth2HttpClient::new()
let result = request.execute(http_client).await
```

**特徴:**
- ✅ 既に実装済み（追加実装不要）
- ✅ 標準的なOAuth2フロー
- ❌ Google Cloud Consoleで設定が必要
- ❌ クライアントシークレットの管理が必要

**用途:**
- サーバー間API呼び出し
- バックグラウンドジョブ
- 定期実行タスク

### 2.2 Service Account認証 ❌

**未実装 - 追加実装が必要**

Google Service Accountは、JWT（JSON Web Token）を使った自己署名認証方式です。

**特徴:**
- ✅ より安全（private keyベース）
- ✅ Googleで推奨される方式
- ✅ クライアントシークレット不要
- ❌ JWT生成・署名の実装が必要
- ❌ private keyの管理が必要

**フロー:**
```
1. Service Accountのprivate keyを使ってJWT作成
2. JWTに署名（RS256）
3. JWTをGoogleトークンエンドポイントに送信
4. アクセストークンを取得
```

## 3. Google Service Account認証の実装計画

### 3.1 必要なコンポーネント

#### JWT生成
```moonbit
// lib/service_account/jwt.mbt
pub struct ServiceAccountJwt {
  header : JwtHeader
  claims : ServiceAccountClaims
  signature : String
}

pub struct JwtHeader {
  alg : String  // "RS256"
  typ : String  // "JWT"
}

pub struct ServiceAccountClaims {
  iss : String     // Service Account email
  scope : String   // スペース区切りのスコープ
  aud : String     // "https://oauth2.googleapis.com/token"
  exp : Int64      // 発行時刻 + 3600
  iat : Int64      // 発行時刻
}
```

#### JWT署名
```moonbit
// lib/service_account/signer.mbt
pub trait JwtSigner {
  fn sign(data : String) -> Result[String, SignError]
}

pub struct Rs256Signer {
  private_key : String  // PEM形式
}

pub fn Rs256Signer::new(private_key : String) -> Rs256Signer

pub fn Rs256Signer::sign(
  self : Rs256Signer,
  data : String
) -> Result[String, SignError] {
  // RS256署名の実装
  // 依存: RSA暗号化ライブラリが必要
}
```

#### Service Account認証リクエスト
```moonbit
// lib/service_account/auth.mbt
pub struct ServiceAccountAuth {
  service_account_email : String
  private_key : String
  scopes : Array[String]
  token_url : String
}

pub fn ServiceAccountAuth::new(
  service_account_email : String,
  private_key : String,
  scopes : Array[String]
) -> ServiceAccountAuth {
  {
    service_account_email,
    private_key,
    scopes,
    token_url: "https://oauth2.googleapis.com/token",
  }
}

pub fn ServiceAccountAuth::get_access_token(
  self : ServiceAccountAuth
) -> @http.Future[@oauth2.TokenResponse] {
  // 1. JWT生成
  let jwt = self.create_jwt()?

  // 2. JWT署名
  let signed_jwt = self.sign_jwt(jwt)?

  // 3. トークンリクエスト
  let response = self.exchange_jwt_for_token(signed_jwt).await?

  Ok(response)
}
```

### 3.2 実装の課題

#### 課題1: RSA暗号化ライブラリ

**問題:** MoonBitでRS256署名を実装するには、RSA暗号化ライブラリが必要

**選択肢:**

**Option A: 外部バイナリ呼び出し**
```moonbit
// opensslコマンドを使用
fn sign_with_openssl(data : String, key_path : String) -> Result[String, Error] {
  let cmd = "openssl dgst -sha256 -sign \{key_path}"
  // コマンド実行
}
```
- ✅ 実装が簡単
- ❌ opensslへの依存
- ❌ クロスプラットフォーム対応が困難

**Option B: WebAssembly暗号化ライブラリ**
```moonbit
// Wasmバイナリとして暗号化ライブラリを使用
// 例: Rustで書かれた暗号化ライブラリをWasmコンパイル
```
- ✅ クロスプラットフォーム
- ❌ 複雑な実装
- ❌ Wasmバイナリの管理

**Option C: MoonBit純粋実装**
```moonbit
// RSA暗号化をMoonBitで実装
```
- ✅ 依存なし
- ❌ 非常に複雑（数百行のコード）
- ❌ セキュリティ監査が必要
- ❌ パフォーマンス懸念

**Option D: 既存のMoonBit暗号化ライブラリを探す**
```moonbit
// mooncakes.ioで暗号化ライブラリを探す
```
- ✅ 最も理想的
- ❓ ライブラリが存在するか不明

**推奨:** Option Dを調査 → なければOption A（開発環境用）+ Option B（本番環境用）

#### 課題2: private keyの管理

**問題:** Service Accountのprivate keyを安全に管理する必要がある

**ベストプラクティス:**
- ✅ 環境変数から読み込み
- ✅ ファイルシステムから読み込み（権限制限）
- ✅ Secret管理サービス（Google Secret Manager等）
- ❌ コードにハードコードしない

```moonbit
// 環境変数から読み込み
pub fn load_private_key_from_env() -> Result[String, Error] {
  env::get("GOOGLE_SERVICE_ACCOUNT_KEY")
}

// ファイルから読み込み
pub fn load_private_key_from_file(path : String) -> Result[String, Error] {
  @fs.read_to_string(path)
}

// JSON keyファイルのパース
pub struct ServiceAccountKeyFile {
  type_ : String  // "service_account"
  project_id : String
  private_key_id : String
  private_key : String
  client_email : String
  client_id : String
  auth_uri : String
  token_uri : String
}

pub fn parse_service_account_key_file(
  json : String
) -> Result[ServiceAccountKeyFile, Error] {
  // JSONパース
}
```

### 3.3 実装優先度

| 機能 | 優先度 | 工数 | 理由 |
|---|---|---|---|
| Client Credentials Flow ラッパー | **高** | 2-3時間 | 既存ライブラリで実装済み |
| Service Account JWT生成 | 中 | 4-6時間 | RSA署名ライブラリ次第 |
| Service Account認証 | 中 | 3-4時間 | JWT生成後は比較的簡単 |
| Private key管理 | 高 | 2-3時間 | セキュリティ上重要 |

## 4. 更新された実装計画

### Phase 1.5: Server-to-Server認証（推定: 0.5-1日）

#### Client Credentials Flow ラッパー（2-3時間）
```moonbit
// lib/google_client_credentials.mbt
pub struct GoogleClientCredentials {
  client_id : String
  client_secret : String
  scopes : Array[String]
}

pub fn GoogleClientCredentials::new(
  client_id : String,
  client_secret : String,
  scopes : Array[String]
) -> GoogleClientCredentials

pub fn GoogleClientCredentials::get_access_token(
  self : GoogleClientCredentials
) -> @http.Future[@oauth2.TokenResponse] {
  let request = @oauth2.ClientCredentialsRequest::new(
    @googleauth.google_token_url,
    @oauth2.ClientId::new(self.client_id),
    @oauth2.ClientSecret::new(self.client_secret),
    self.scopes.map(@oauth2.Scope::new),
  )

  let http_client = @oauth2.OAuth2HttpClient::new()
  request.execute(http_client)
}
```

**テスト:**
- ユニットテスト
- Google APIでの実通信テスト

#### Service Account調査と基本実装（2-4時間）

1. **RSA暗号化ライブラリの調査**（1時間）
   - mooncakes.ioで検索
   - 既存ライブラリの評価

2. **JWT生成の実装**（1-2時間）
   - JwtHeader, ServiceAccountClaims型定義
   - Base64URL encoding
   - JWT文字列生成

3. **実装可能性の評価**（1時間）
   - 署名ライブラリが見つかった場合 → 完全実装
   - 見つからない場合 → 代替案の検討

### Phase 2（条件付き）: Service Account完全実装（推定: 4-6時間）

**条件:** RSA署名ライブラリが利用可能な場合

**実装項目:**
1. RS256署名実装（または統合）
2. ServiceAccountAuth実装
3. Private key管理
4. 統合テスト
5. ドキュメント

## 5. 使用例の比較

### 5.1 Client Credentials Flow（実装済み）

```moonbit
// シンプルで実装済み
let credentials = @googleauth.GoogleClientCredentials::new(
  "client-id",
  "client-secret",
  ["https://www.googleapis.com/auth/cloud-platform"]
)

let token = credentials.get_access_token().await?
println("Access Token: \{token.access_token()}")
```

**メリット:**
- ✅ 既存ライブラリで動作
- ✅ 追加実装ほぼ不要
- ✅ すぐに使える

**デメリット:**
- ❌ クライアントシークレット管理が必要
- ❌ Googleで推奨されない場合がある

### 5.2 Service Account認証（未実装）

```moonbit
// より安全だが実装が必要
let key_file = load_service_account_key("service-account.json")?
let auth = @googleauth.ServiceAccountAuth::new(
  key_file.client_email,
  key_file.private_key,
  ["https://www.googleapis.com/auth/cloud-platform"]
)

let token = auth.get_access_token().await?
println("Access Token: \{token.access_token()}")
```

**メリット:**
- ✅ より安全（private keyベース）
- ✅ Googleで推奨
- ✅ クライアントシークレット不要

**デメリット:**
- ❌ 追加実装が必要（JWT署名）
- ❌ RSA暗号化ライブラリへの依存

## 6. 推奨アプローチ

### 短期（Phase 1.5）

**Client Credentials Flow のラッパー実装を優先**

理由:
1. ✅ 既存ライブラリで動作
2. ✅ 実装が簡単（2-3時間）
3. ✅ すぐに使える

### 中期（Phase 2 - 条件付き）

**RSA暗号化ライブラリの調査と評価**

1. mooncakes.ioで暗号化ライブラリを探す
2. 適切なライブラリが見つかれば Service Account実装
3. 見つからなければ外部バイナリ（openssl）との統合を検討

### 長期

**MoonBitエコシステムへの貢献**

- RSA暗号化ライブラリが不足している場合、コミュニティに提案
- または独自に暗号化ライブラリを実装・公開

## 7. まとめ

### 現状の対応状況

| 認証方式 | ライブラリ対応 | ラッパー実装 | 推奨度 |
|---|---|---|---|
| Authorization Code Flow | ✅ 完全 | Phase 1 | ⭐⭐⭐⭐⭐ |
| Client Credentials Flow | ✅ 完全 | Phase 1.5 | ⭐⭐⭐⭐☆ |
| Service Account | ❌ 未実装 | Phase 2 | ⭐⭐⭐⭐⭐ |

### 実装推奨

1. **Phase 1.5 を追加:** Client Credentials Flow のGoogle特有ラッパー実装
   - 工数: 2-3時間
   - 優先度: 高

2. **RSA暗号化ライブラリの調査:** 次のステップの判断材料
   - 工数: 1時間
   - 優先度: 中

3. **Service Account実装:** ライブラリが利用可能な場合
   - 工数: 4-6時間
   - 優先度: 中（条件付き）

### 更新されたTodoへの追加項目

```markdown
### Phase 1.5: Server-to-Server認証（推定: 0.5-1日）

#### Client Credentials Flow ラッパー（2-3時間）
- [ ] lib/google_client_credentials.mbt 作成
  - [ ] GoogleClientCredentials構造体
  - [ ] get_access_token() メソッド
  - [ ] ユニットテスト

#### RSA暗号化ライブラリ調査（1時間）
- [ ] mooncakes.ioで暗号化ライブラリ検索
- [ ] 既存ライブラリの評価
- [ ] Service Account実装可能性の判断

### Phase 2（条件付き）: Service Account実装（推定: 4-6時間）
- [ ] lib/service_account/jwt.mbt 作成
- [ ] lib/service_account/signer.mbt 作成
- [ ] lib/service_account/auth.mbt 作成
- [ ] Private key管理機能
- [ ] 統合テスト
```

---

**結論:** Server-to-Server認証は**既存ライブラリで部分的に対応済み**（Client Credentials Flow）。Google特有のラッパーとService Account認証を追加実装することで、完全な対応が可能です。
