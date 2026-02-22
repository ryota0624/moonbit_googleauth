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

### Phase 2: 高度な機能（推定: 0.5-1日）

#### トークン管理（2-3時間）
- [ ] lib/token_manager.mbt 作成
  - [ ] TokenManager構造体
  - [ ] is_expired() メソッド
  - [ ] needs_refresh() メソッド
  - [ ] ユニットテスト

#### トークンストレージ（2-3時間）
- [ ] lib/token_storage.mbt 作成
  - [ ] TokenStorage trait
  - [ ] FileTokenStorage実装例
  - [ ] ユニットテスト

#### 高レベルAPI（2-3時間）
- [ ] lib/google_api_client.mbt 作成
  - [ ] GoogleApiClient構造体
  - [ ] 自動トークンリフレッシュ機能
  - [ ] ユニットテスト

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
