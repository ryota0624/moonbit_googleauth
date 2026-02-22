# Goal

google API用の認証情報を取得するための実装

# Todos

## 調査フェーズ（完了）

- [x] google API用の認証情報を取得するための実装をするための調査
 - [x] 参考にするライブラリの決定
 - [x] 必要な機能の洗い出し
 - [x] 実装順序の検討
 - [x] 結合動作検証方法の検討

**成果物:**
- `docs/investigation.md` - 調査レポート
- `docs/features.md` - 機能仕様書
- `docs/implementation_plan.md` - 実装計画
- `docs/testing_strategy.md` - テスト戦略
- `docs/README.md` - ドキュメントサマリー

## 計画見直し: ryota0624/oauth2ライブラリを活用

**重要な決定:** 既存のMoonBit OAuth2ライブラリ（`ryota0624/oauth2`）を使用することで、実装期間を**2-3週間 → 3-5日**に短縮できます。

詳細: `docs/revised_plan_with_oauth2_lib.md`

### 環境セットアップ（完了）
- [x] ryota0624/oauth2ライブラリの依存関係を追加
- [ ] Google Cloud Consoleでテスト用プロジェクト作成

### Phase 1: Google OAuth2 ラッパー実装（推定: 1-2日）

#### Google定数定義（2-3時間）
- [x] lib/google_constants.mbt 作成
  - [x] Google認証エンドポイント定義
  - [x] 一般的なスコープ定数定義（Drive, Gmail, Calendar等）
  - [x] ユニットテスト

#### GoogleOAuth2Client ラッパー（3-4時間）
- [x] lib/google_client.mbt 作成
  - [x] GoogleOAuth2Client構造体
  - [x] build_auth_url() メソッド
  - [x] verify_callback() メソッド
  - [x] ユニットテスト

#### ヘルパー関数（2-3時間）
- [x] lib/google_helpers.mbt 作成
  - [x] parse_callback_url() - リダイレクトURLパース
  - [x] parse_error_response() - エラーレスポンスパース
  - [x] PkceStorage trait定義
  - [x] ユニットテスト

#### 統合とテスト（3-4時間）
- [ ] examples/basic_auth/ サンプル作成
- [ ] 実際のGoogle OAuth2で動作確認
- [ ] E2Eテスト手順書作成

### Phase 1.5: Server-to-Server認証（推定: 1.5-2.5日）⚠️ **工数見直し**

詳細:
- `docs/server_to_server_auth.md`
- `docs/application_default_credentials.md` ⭐ **NEW**

#### 1. Client Credentials Flow ラッパー（2-3時間）
- [x] lib/google_client_credentials.mbt 作成
  - [x] GoogleClientCredentials構造体
  - [x] get_token_from_client_credentials() メソッド（既存ライブラリのラッパー）
  - [x] ユニットテスト
  - [ ] 実通信テスト（Phase 2対象）

**注:** Client Credentials Flow自体は `ryota0624/oauth2` で既に実装済み。Google特有のラッパーのみ実装。

#### 2. Application Default Credentials (ADC)（3-5時間）⭐ **NEW - 優先度高**

**重要:** プロダクション環境では必須の機能

- [x] lib/service_account_types.mbt 作成（共通型定義）
  - [x] ServiceAccountCredentials型定義
  - [x] AdcError型定義
  - [x] MetadataError型定義
  - [x] その他エラー型定義

- [x] lib/service_account_adc.mbt 作成
  - [x] load_credentials_from_env() 実装（Phase 2対象）
  - [x] load_credentials_from_file() 実装（Phase 2対象）
  - [x] parse_service_account_key() 実装
    - [x] JSON keyファイルパース
    - [x] 必須フィールド検証
  - [x] validate_credentials() 実装
  - [x] ユニットテスト
    - [x] JSONパース成功/失敗
    - [x] 必須フィールド検証

#### 3. Metadata Server認証（3-4時間）⭐ **NEW - 優先度高**

**重要:** GCE/GKE/Cloud Run環境では必須の機能

- [x] lib/service_account_metadata.mbt 作成
  - [x] MetadataServerConfig型定義
  - [x] get_token_from_metadata_server() 実装
    - [x] HTTPリクエスト（Metadata-Flavor: Google ヘッダー） - Phase 2対象
    - [x] エンドポイント: http://metadata.google.internal/computeMetadata/v1/...
    - [x] レスポンスパース - Phase 2対象
  - [x] is_metadata_server_available() 実装
    - [x] タイムアウト付きチェック（1秒）
  - [x] MetadataTokenResponse型定義
  - [x] MetadataError型定義
  - [x] ユニットテスト
  - [ ] 統合テスト（Cloud Run/GCE環境）

#### 4. 自動認証検出（3-5時間）⭐ **NEW - 優先度高**

**重要:** 環境に応じて自動的に最適な認証方法を選択

- [x] lib/google_auth_client.mbt 作成
  - [x] GoogleAuthClient型定義
  - [x] AuthCredentialsType enum定義（既存）
  - [x] auto_detect_and_authenticate() 実装
    - [x] Step 1: 明示的な認証情報チェック（Phase 2対象）
    - [x] Step 2: ADC (環境変数) チェック
    - [x] Step 3: Metadata Server チェック
    - [x] Step 4: エラー（すべて失敗）
  - [x] get_access_token() 実装
  - [x] ユニットテスト
  - [ ] E2Eテスト（複数環境）
    - [ ] ローカル環境（ADC）
    - [ ] GCE環境（Metadata Server）
    - [ ] Cloud Run環境（Metadata Server）

#### 5. RSA暗号化ライブラリ調査（1時間）⭐ **完了**
- [x] mooncakes.ioで暗号化/RSAライブラリ検索
- [x] 既存ライブラリの評価
- [x] Service Account JWT実装可能性の判断

**調査結果:** RSAライブラリは開発中で、本番環境での使用に不確実性がある。
実装スキップを推奨（詳細は `docs/completed/20260222_rsa_library_investigation.md` を参照）

#### 6. Service Account JWT実装（条件付き: 4-6時間）⚠️ **スキップ**
**理由:** RSA署名ライブラリが開発中のため、条件を満たしていない
**優先度:** 低（ADC/Metadataがあれば代替可能）

**スキップ理由:**
- ADCとMetadata Serverで本番環境での認証が完全にカバー可能
- RSAライブラリの成熟度が不足している
- Phase 2以降での改善を待つことが適切

Future consideration in Phase 2 when RSA library stabilizes

### Phase 2: 高度な機能（完了）✅

#### トークン管理（完了）
- [x] lib/token_manager.mbt 作成
  - [x] TokenManager構造体
  - [x] is_expired() メソッド
  - [x] needs_refresh() メソッド
  - [x] ユニットテスト (17件追加)

#### トークンストレージ（完了）
- [x] lib/token_storage.mbt 作成
  - [x] TokenStorage trait（関数ベース設計）
  - [x] InMemoryTokenStorage実装
  - [x] FileTokenStorage スタブ実装
  - [x] ユニットテスト (8件追加)

#### 高レベルAPI（完了）
- [x] lib/google_api_client.mbt 作成
  - [x] GoogleApiClient構造体
  - [x] 自動トークンリフレッシュ機能
  - [x] ユニットテスト (12件追加)

### ドキュメント整備（推定: 0.5-1日）
- [ ] README.md更新
  - [ ] プロジェクト概要
  - [ ] インストール方法
  - [ ] クイックスタート
  - [ ] 基本的な使用例
- [ ] docs/quickstart.md作成
- [ ] docs/api_reference.md作成
- [ ] docs/google_setup.md作成（Google Console設定手順）
- [ ] examples/の充実

### Phase 3（オプション）: OpenID Connect完全対応（1-2日）
- [ ] ID Token署名検証
- [ ] Google UserInfo endpoint統合
- [ ] email_verified等のクレーム検証

注: ryota0624/oauth2に既に基本実装があるため、必要に応じて拡張

## 残存するTODO（Phase 2以降で実装予定）

### google_auth_client.mbt
- [ ] **Step 1: 明示的な認証情報チェック**（現在: Phase 2以降で実装予定）
  - Location: Line 52-53
  - 目的: 構成ファイルやパラメータから直接認証情報を取得するオプション
  - 優先度: 低（ADCとMetadata Serverでカバー可能）

- [ ] **実際のトークン取得実装**（現在: ダミー返却 InvalidCredentials）
  - Location: Line 104-109
  - 目的: ServiceAccount認証情報を使用した実トークン取得
  - 依存: RSA署名ライブラリ（開発中の為スキップ）
  - 優先度: 中（Phase 2.5で検討）

### google_client_credentials.mbt
- [ ] **Client Credentials Flow トークン取得実装**（現在: ダミー返却）
  - Location: Line 59
  - 目的: OAuth2 Client Credentials Flow でのトークン取得
  - 実装内容:
    - `get_token_from_client_credentials()`: トークン取得ロジック
    - `get_scoped_token_from_client_credentials()`: スコープ付きトークン取得
  - 依存: HTTP クライアント、JSON パース
  - 優先度: 高（Phase 2.5対象）

### service_account_adc.mbt
- [ ] **環境変数からの認証情報読み込み**（現在: NotSet エラー返却）
  - Location: Line 20-26
  - 機能: `load_credentials_from_env()` - GOOGLE_APPLICATION_CREDENTIALS 環境変数対応
  - 依存: 環境変数アクセス機能
  - 優先度: 高（実運用必須）

- [ ] **ファイルからの認証情報読み込み**（現在: IoCCError 返却）
  - Location: Line 38-44
  - 機能: `load_credentials_from_file()` - JSONファイルの読み込みと解析
  - 依存: ファイルI/O機能
  - 優先度: 高（実運用必須）

- [ ] **JSON パース詳細化**（現在: モック実装）
  - Location: Line 94 コメント参照
  - 目的: JSON.parse() を使用した完全パース
  - 含まれるフィール:
    - type, project_id, private_key_id, private_key
    - client_email, client_id, auth_uri, token_uri
    - auth_provider_x509_cert_url, client_x509_cert_url
  - 優先度: 中

### service_account_metadata.mbt
- [ ] **Metadata Server 有効性確認の実装**（現在: false 固定返却）
  - Location: Line 60-66
  - 機能: `is_metadata_server_available()` - タイムアウト付きチェック
  - 実装内容:
    - エンドポイント: http://metadata.google.internal/computeMetadata/v1/
    - ヘッダー: Metadata-Flavor: Google
    - タイムアウト: 1秒
  - 依存: HTTP クライアント（タイムアウト対応）
  - 優先度: 高（GCP環境での認証に必須）

- [ ] **Metadata Server からのトークン取得実装**（現在: ダミー返却）
  - Location: Line 77-93
  - 機能: `get_access_token_from_metadata_server()` - 実トークン取得
  - 実装内容:
    - エンドポイント: http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity
    - JSON レスポンス解析
    - エラーハンドリング（タイムアウト、接続失敗など）
  - 依存: HTTP クライアント、JSON パース
  - 優先度: 高（GCP環境での認証に必須）

### token_manager.mbt
- [ ] **システム時刻の統合**（現在: オフセットベース）
  - Location: Line 13-14 issued_at_offset
  - 計画: Phase 3 で `issued_at_unix_timestamp` に置き換え
  - 影響範囲: is_expired(), needs_refresh(), remaining_seconds()
  - 優先度: 中（Phase 3確定）

### token_storage.mbt
- [ ] **FileTokenStorage 実装**（現在: スタブ）
  - Location: Line 67-96
  - 機能: ファイルベースのトークン永続化
  - 実装内容:
    - TokenManager の JSON シリアライゼーション
    - ファイル書込・読込
    - 暗号化検討（オプション）
  - 依存: ファイルI/O、JSON パース
  - 優先度: 高（実運用向け）

### google_api_client.mbt
- [ ] **レスポンスメタデータからの expires_in 抽出**（現在: 固定値 3600秒）
  - Location: Line 57-58
  - 計画: Phase 3 でトークンレスポンスから実際の有効期限を抽出
  - 実装: Token エンドポイントレスポンスから `expires_in` フィールド取得
  - 優先度: 中（Phase 3確定）
