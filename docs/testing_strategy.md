# Google OAuth2認証ライブラリ テスト戦略

## 1. テストの全体方針

### 1.1 テストピラミッド

```
       /\
      /E2E\          少数（実際のGoogle API）
     /------\
    /統合テスト\       中程度（モックサーバー）
   /----------\
  /ユニットテスト\     多数（個別関数）
 /--------------\
```

**方針:**
- ユニットテストを中心に、コードカバレッジ80%以上を目指す
- 統合テストでHTTP通信とフロー全体を検証
- E2Eテストは手動実行を基本とし、CI/CDでは実施しない（認証情報管理の複雑さを回避）

### 1.2 テストレベルの定義

| レベル | 目的 | 実行頻度 | 環境 |
|---|---|---|---|
| ユニット | 個別関数の動作検証 | 常時（開発中） | ローカル |
| 統合 | コンポーネント間連携 | コミット前 | ローカル + CI |
| E2E | 実際のAPI連携 | リリース前 | 手動 |

## 2. ユニットテスト

### 2.1 対象コンポーネント

#### 2.1.1 Config管理（config.mbt）

**テストケース:**

```moonbit
test "new_config creates valid configuration" {
  let config = new_config(
    "client_id",
    "client_secret",
    "http://localhost/callback"
  )
  assert_eq(config.client_id, "client_id")
  assert_eq(config.client_secret, "client_secret")
  assert_eq(config.redirect_url, "http://localhost/callback")
}

test "with_scopes adds scopes correctly" {
  let config = new_config("id", "secret", "url")
    |> with_scopes(["scope1", "scope2"])
  assert_eq(config.scopes.length(), 2)
  assert_true(config.scopes.contains("scope1"))
}

test "validate_config rejects empty client_id" {
  let config = OAuth2Config{
    client_id: "",
    client_secret: "secret",
    ...
  }
  let result = validate_config(config)
  assert_true(result.is_err())
}

test "validate_config rejects non-HTTPS redirect_url" {
  let config = OAuth2Config{
    redirect_url: "http://example.com/callback",
    ...
  }
  let result = validate_config(config)
  assert_true(result.is_err())
}

test "validate_config allows localhost with HTTP" {
  let config = OAuth2Config{
    redirect_url: "http://localhost:8080/callback",
    ...
  }
  let result = validate_config(config)
  assert_true(result.is_ok())
}
```

#### 2.1.2 ユーティリティ関数（utils.mbt）

**テストケース:**

```moonbit
test "url_encode handles special characters" {
  assert_eq(url_encode("hello world"), "hello%20world")
  assert_eq(url_encode("test@example.com"), "test%40example.com")
  assert_eq(url_encode("foo+bar"), "foo%2Bbar")
}

test "build_query_string creates valid query" {
  let params = Map.from_array([
    ("key1", "value1"),
    ("key2", "value with spaces")
  ])
  let query = build_query_string(params)
  assert_true(query.contains("key1=value1"))
  assert_true(query.contains("key2=value%20with%20spaces"))
}

test "generate_state produces unique values" {
  let state1 = generate_state()
  let state2 = generate_state()
  assert_ne(state1, state2)
}

test "generate_state produces sufficient length" {
  let state = generate_state()
  assert_true(state.length() >= 32)
}
```

#### 2.1.3 認可URL生成（auth_url.mbt）

**テストケース:**

```moonbit
test "generate_auth_url includes required parameters" {
  let config = new_config("client_id", "secret", "http://localhost/cb")
    |> with_scopes(["scope1"])
  let options = AuthUrlOptions{
    state: "test_state",
    access_type: None,
    prompt: None,
    include_granted_scopes: false
  }
  let url = generate_auth_url(config, options)

  assert_true(url.contains("client_id=client_id"))
  assert_true(url.contains("redirect_uri="))
  assert_true(url.contains("response_type=code"))
  assert_true(url.contains("scope=scope1"))
  assert_true(url.contains("state=test_state"))
}

test "generate_auth_url handles multiple scopes" {
  let config = new_config("id", "secret", "url")
    |> with_scopes(["scope1", "scope2", "scope3"])
  let url = generate_auth_url(config, default_options)

  // スコープがスペース区切りまたはURLエンコードされたスペースで連結
  assert_true(
    url.contains("scope=scope1%20scope2%20scope3") ||
    url.contains("scope=scope1+scope2+scope3")
  )
}

test "generate_auth_url includes optional parameters" {
  let options = AuthUrlOptions{
    state: "state",
    access_type: Some("offline"),
    prompt: Some("consent"),
    include_granted_scopes: true
  }
  let url = generate_auth_url(config, options)

  assert_true(url.contains("access_type=offline"))
  assert_true(url.contains("prompt=consent"))
  assert_true(url.contains("include_granted_scopes=true"))
}
```

#### 2.1.4 認可レスポンスのパース（auth_url.mbt）

**テストケース:**

```moonbit
test "parse_authorization_response extracts code" {
  let url = "http://localhost/cb?code=auth_code&state=test_state"
  let response = parse_authorization_response(url)

  assert_true(response.is_ok())
  let resp = response.unwrap()
  assert_eq(resp.code, Some("auth_code"))
  assert_eq(resp.state, "test_state")
  assert_eq(resp.error, None)
}

test "parse_authorization_response handles error response" {
  let url = "http://localhost/cb?error=access_denied&state=test_state"
  let response = parse_authorization_response(url)

  assert_true(response.is_ok())
  let resp = response.unwrap()
  assert_eq(resp.code, None)
  assert_eq(resp.error, Some("access_denied"))
}

test "verify_state succeeds with matching state" {
  let response = AuthorizationResponse{
    code: Some("code"),
    state: "expected_state",
    error: None,
    error_description: None
  }
  let result = verify_state(response, "expected_state")

  assert_true(result.is_ok())
  assert_eq(result.unwrap(), "code")
}

test "verify_state fails with mismatched state" {
  let response = AuthorizationResponse{
    code: Some("code"),
    state: "wrong_state",
    error: None,
    error_description: None
  }
  let result = verify_state(response, "expected_state")

  assert_true(result.is_err())
  match result {
    Err(StateVerificationFailed(_)) => assert_true(true)
    _ => assert_true(false)
  }
}
```

#### 2.1.5 トークン管理（token.mbt）

**テストケース:**

```moonbit
test "token_from_response calculates expires_at correctly" {
  let response = TokenResponse{
    access_token: "token",
    expires_in: 3600,
    refresh_token: None,
    scope: "scope1",
    token_type: "Bearer"
  }

  let before = get_current_timestamp()
  let token = token_from_response(response)
  let after = get_current_timestamp()

  assert_true(token.expires_at >= before + 3600)
  assert_true(token.expires_at <= after + 3600)
}

test "is_expired returns true for expired token" {
  let token = Token{
    access_token: "token",
    refresh_token: None,
    expires_at: get_current_timestamp() - 100,  // 100秒前
    scope: "scope",
    token_type: "Bearer"
  }

  assert_true(is_expired(token))
}

test "is_expired returns false for valid token" {
  let token = Token{
    expires_at: get_current_timestamp() + 3600,  // 1時間後
    ...
  }

  assert_false(is_expired(token))
}

test "needs_refresh with default threshold" {
  let expires_at = get_current_timestamp() + 3600
  let token = Token{ expires_at, ... }

  // 90%経過（540秒残り）
  let near_expiry = Token{
    expires_at: get_current_timestamp() + 360,
    ...
  }

  assert_false(needs_refresh(token, 0.9))
  assert_true(needs_refresh(near_expiry, 0.9))
}
```

#### 2.1.6 エラーハンドリング（errors.mbt）

**テストケース:**

```moonbit
test "OAuth2Error displays meaningful messages" {
  let error = InvalidRequest("Missing client_id parameter")
  assert_true(error.to_string().contains("client_id"))

  let error2 = StateVerificationFailed("States do not match")
  assert_true(error2.to_string().contains("state"))
}
```

### 2.2 ユニットテストの実行

**MoonBitのテストコマンド:**
```bash
# 全ユニットテスト実行
moon test

# 特定ファイルのテスト
moon test googleauth/config_test.mbt

# カバレッジ計測
moon test --coverage
```

### 2.3 ユニットテストのカバレッジ目標

| コンポーネント | 目標カバレッジ |
|---|---|
| Config管理 | 90% |
| ユーティリティ | 95% |
| 認可URL生成 | 90% |
| レスポンスパース | 95% |
| トークン管理 | 85% |
| エラーハンドリング | 80% |

## 3. 統合テスト

### 3.1 モックHTTPサーバー

**目的:** 実際のGoogle APIを使わずにHTTP通信を検証

**実装方法:**

#### Option 1: MoonBitでシンプルなモックサーバー実装

```moonbit
// test/mock_server.mbt
struct MockServer {
  responses: Map[String, MockResponse]
}

struct MockResponse {
  status: Int
  body: String
  headers: Map[String, String]
}

fn create_mock_server() -> MockServer {
  MockServer{
    responses: Map.new()
  }
}

fn add_response(
  server: MockServer,
  path: String,
  response: MockResponse
) -> MockServer {
  server.responses.set(path, response)
  server
}
```

#### Option 2: 既存のMoonBit HTTPサーバーライブラリを使用

**調査が必要:** MoonBitのHTTPサーバーライブラリの有無

### 3.2 統合テストケース

#### 3.2.1 トークン取得フロー

**テストシナリオ:**
1. 認可URL生成
2. モックサーバーが認可コードを返す
3. トークン交換リクエスト
4. モックサーバーがトークンレスポンスを返す
5. トークンを正しくパース

```moonbit
test "complete authorization code flow with mock server" {
  // モックサーバーセットアップ
  let mock = create_mock_server()
    |> add_response("/token", MockResponse{
      status: 200,
      body: json!({
        "access_token": "ya29.test_token",
        "expires_in": 3600,
        "token_type": "Bearer",
        "scope": "https://www.googleapis.com/auth/userinfo.email"
      }),
      headers: Map.from_array([
        ("Content-Type", "application/json")
      ])
    })

  // Config作成（モックサーバーURLを使用）
  let config = OAuth2Config{
    client_id: "test_client",
    client_secret: "test_secret",
    auth_url: "http://localhost:8888/auth",
    token_url: "http://localhost:8888/token",
    redirect_url: "http://localhost/callback",
    scopes: ["email"]
  }

  // トークン取得
  let result = exchange_code_for_token(config, "test_auth_code")

  assert_true(result.is_ok())
  let token_response = result.unwrap()
  assert_eq(token_response.access_token, "ya29.test_token")
  assert_eq(token_response.expires_in, 3600)
}
```

#### 3.2.2 エラーレスポンスハンドリング

```moonbit
test "handles invalid_grant error" {
  let mock = create_mock_server()
    |> add_response("/token", MockResponse{
      status: 400,
      body: json!({
        "error": "invalid_grant",
        "error_description": "Code was already redeemed"
      }),
      headers: Map.from_array([
        ("Content-Type", "application/json")
      ])
    })

  let result = exchange_code_for_token(config, "used_code")

  assert_true(result.is_err())
  match result {
    Err(InvalidGrant(desc)) => {
      assert_true(desc.contains("redeemed"))
    }
    _ => assert_true(false)
  }
}
```

#### 3.2.3 トークンリフレッシュフロー

```moonbit
test "token refresh flow with mock server" {
  let mock = create_mock_server()
    |> add_response("/token", MockResponse{
      status: 200,
      body: json!({
        "access_token": "ya29.new_token",
        "expires_in": 3600,
        "token_type": "Bearer",
        "scope": "email"
      }),
      headers: Map.from_array([
        ("Content-Type", "application/json")
      ])
    })

  let result = refresh_access_token(config, "refresh_token_value")

  assert_true(result.is_ok())
  let token_response = result.unwrap()
  assert_eq(token_response.access_token, "ya29.new_token")
}
```

### 3.3 統合テストの実行環境

**ローカル実行:**
```bash
# モックサーバーを起動（別ターミナル）
moon run test/mock_server

# 統合テストを実行
moon test --integration
```

**CI/CD環境:**
- GitHub Actions / GitLab CI で自動実行
- モックサーバーをサービスコンテナとして起動
- 全統合テストを実行

## 4. E2Eテスト

### 4.1 手動E2Eテスト

**目的:** 実際のGoogle OAuth2 APIとの完全な連携を検証

**前提条件:**
1. Google Cloud Consoleでプロジェクト作成
2. OAuth 2.0クライアントIDの作成
3. リダイレクトURIの設定（`http://localhost:8080/callback`）
4. テスト用のクライアントIDとシークレットを環境変数に設定

#### 4.1.1 基本フローのE2Eテスト

**手順書:**

```markdown
# E2Eテスト手順: 基本的な認証フロー

## セットアップ
1. 環境変数を設定
   ```bash
   export GOOGLE_CLIENT_ID="your_client_id"
   export GOOGLE_CLIENT_SECRET="your_client_secret"
   ```

2. サンプルアプリをビルド
   ```bash
   moon build cmd/main
   ```

## テスト実行
1. サンプルアプリを実行
   ```bash
   moon run cmd/main
   ```

2. 表示されたURLをブラウザで開く

3. Googleアカウントでログイン

4. スコープへの同意を確認

5. リダイレクト後のURLをコピー

6. ターミナルにURLを貼り付け

7. アクセストークンが表示されることを確認

## 期待結果
- ✅ 認可URLが正しく生成される
- ✅ Googleの同意画面が表示される
- ✅ リダイレクトが正常に行われる
- ✅ アクセストークンが取得できる
- ✅ トークンに正しいスコープが含まれる

## トラブルシューティング
- リダイレクトURIエラー → Google Cloud Consoleで設定確認
- 無効なクライアント → 認証情報を再確認
- スコープエラー → APIが有効化されているか確認
```

#### 4.1.2 トークンリフレッシュのE2Eテスト

**手順書:**

```markdown
# E2Eテスト手順: トークンリフレッシュ

## セットアップ
1. 基本フローでリフレッシュトークンを取得
   - `access_type=offline` オプションを使用

2. リフレッシュトークンを保存

## テスト実行
1. リフレッシュトークンを使ってサンプルアプリを実行
   ```bash
   moon run cmd/refresh_example -- --refresh-token="your_refresh_token"
   ```

2. 新しいアクセストークンが取得できることを確認

## 期待結果
- ✅ リフレッシュトークンで新しいアクセストークンが取得できる
- ✅ 新しいトークンの有効期限が正しい
```

#### 4.1.3 エラーハンドリングのE2Eテスト

**テストケース:**

| テストケース | 手順 | 期待結果 |
|---|---|---|
| 不正な認可コード | 無効なコードでトークン取得 | InvalidGrantエラー |
| 期限切れリフレッシュトークン | 古いリフレッシュトークンを使用 | InvalidGrantエラー |
| 不正なクライアントシークレット | 間違ったシークレットで認証 | UnauthorizedClientエラー |
| ユーザー拒否 | 同意画面で拒否 | AccessDeniedエラー |

### 4.2 半自動E2Eテスト（推奨）

**目的:** E2Eテストを可能な限り自動化

**実装方法:**

#### Option 1: ヘッドレスブラウザ自動化

- Playwrightなどを使用してブラウザ操作を自動化
- テスト用Googleアカウントで自動ログイン
- 同意画面の自動承認

**課題:**
- Googleの認証フローの変更に脆弱
- CAPTCHA等のセキュリティ機構への対応

#### Option 2: Google OAuth2 Playgroundの活用

1. OAuth2 Playground (https://developers.google.com/oauthplayground/) で認可コードを取得
2. そのコードをテストで使用
3. トークン取得以降のフローをテスト

### 4.3 E2Eテストチェックリスト

**リリース前に確認すべき項目:**

- [ ] 基本的な認証フローが動作する
- [ ] リフレッシュトークンが正しく動作する
- [ ] トークン失効が正しく動作する
- [ ] 複数のスコープが正しく処理される
- [ ] 各種エラーが適切にハンドリングされる
- [ ] state パラメータによるCSRF対策が機能する
- [ ] 異なるブラウザで動作する（Chrome, Firefox, Safari）
- [ ] HTTPSとHTTPの両方で動作する（localhost）

## 5. テスト自動化

### 5.1 CI/CD統合

**GitHub Actions設定例:**

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install.sh | bash
          echo "$HOME/.moon/bin" >> $GITHUB_PATH

      - name: Run unit tests
        run: moon test

      - name: Generate coverage report
        run: moon test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  integration-tests:
    runs-on: ubuntu-latest
    services:
      mock-server:
        image: mockserver/mockserver
        ports:
          - 8888:1080
    steps:
      - uses: actions/checkout@v3

      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install.sh | bash
          echo "$HOME/.moon/bin" >> $GITHUB_PATH

      - name: Run integration tests
        run: moon test --integration
        env:
          MOCK_SERVER_URL: http://localhost:8888

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install.sh | bash
          echo "$HOME/.moon/bin" >> $GITHUB_PATH

      - name: Run formatter check
        run: moon fmt --check

      - name: Run linter
        run: moon check
```

### 5.2 継続的テスト

**開発フロー:**
```
コード変更 → ユニットテスト → コミット → 統合テスト (CI) → レビュー → マージ → E2E (手動)
```

**頻度:**
- ユニットテスト: 変更ごと
- 統合テスト: コミット/PR時
- E2Eテスト: リリース前

## 6. パフォーマンステスト

### 6.1 レスポンス時間測定

**測定項目:**

```moonbit
test "auth_url_generation_performance" {
  let config = create_test_config()
  let iterations = 1000

  let start = get_timestamp()
  for i in 0..iterations {
    let _ = generate_auth_url(config, default_options)
  }
  let end = get_timestamp()

  let avg_time = (end - start) / iterations
  assert_true(avg_time < 10)  // 10ms未満
}

test "token_exchange_performance" {
  // モックサーバーでトークン取得のレイテンシを測定
  let start = get_timestamp()
  let result = exchange_code_for_token(config, "code")
  let end = get_timestamp()

  let latency = end - start
  assert_true(latency < 500)  // 500ms未満
}
```

### 6.2 メモリ使用量測定

**測定方法:**
- プロファイリングツールを使用
- Config とToken のメモリサイズを確認
- 不要なコピーを避ける最適化

## 7. セキュリティテスト

### 7.1 セキュリティチェックリスト

**OWASP基準に基づく検証:**

- [ ] **CSRF対策:** state パラメータが正しく検証される
- [ ] **HTTPS強制:** 本番環境でHTTPが拒否される
- [ ] **シークレット管理:** クライアントシークレットがログに出力されない
- [ ] **トークン保護:** トークンが安全に保存される
- [ ] **入力検証:** 全ての外部入力が検証される
- [ ] **エラーメッセージ:** 機密情報が含まれていない

### 7.2 脆弱性スキャン

**実施方法:**
1. 依存関係の脆弱性チェック
   ```bash
   moon audit
   ```

2. 静的コード解析
   - MoonBitのlinterを使用
   - セキュリティルールを追加

3. 定期的なセキュリティレビュー

## 8. テストドキュメント

### 8.1 テスト結果レポート

**含めるべき情報:**
- 実行日時
- 実行環境（OS, MoonBitバージョン）
- テスト結果サマリー（成功/失敗/スキップ）
- カバレッジレポート
- パフォーマンス測定結果
- 失敗したテストの詳細

### 8.2 既知の問題トラッカー

**管理すべき情報:**
- 問題の内容
- 再現手順
- 回避策
- 優先度
- 担当者
- ステータス

## 9. まとめ

### 9.1 テスト戦略の要点

1. **ユニットテスト中心:** カバレッジ80%以上を目標
2. **統合テスト:** モックサーバーで自動化
3. **E2Eテスト:** 手動実行を基本とし、リリース前に実施
4. **CI/CD統合:** 自動テストをPRとマージ時に実行
5. **セキュリティ重視:** OWASP基準に基づく検証

### 9.2 テスト実施タイミング

| フェーズ | テストレベル | 実行方法 |
|---|---|---|
| 開発中 | ユニット | 自動（保存時） |
| コミット前 | ユニット + 統合 | ローカル実行 |
| PR作成時 | ユニット + 統合 | CI自動実行 |
| マージ前 | 全自動テスト | CI自動実行 |
| リリース前 | E2E | 手動実行 |

### 9.3 次のステップ

1. ユニットテストフレームワークのセットアップ
2. モックサーバーの実装
3. CI/CD パイプラインの構築
4. テストドキュメントの整備
