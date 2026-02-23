# Steering: Phase 4 - Non-RSA TODO Implementation

## 目的・背景

Phase 3 (async化実装) を完了し、80テストがパスした状態。
残存する TODO のうち、RSA署名ライブラリに依存しない項目を実装することで、
ライブラリの機能性を向上させ、より多くのユースケースに対応する。

## ゴール

- [ ] **Documentation**: README.md、quickstart.md、api_reference.md、google_setup.md を作成し、ユーザーが即座に利用開始できる状態にする
- [ ] **System time integration**: offset ベースから Unix timestamp ベースの時刻管理に移行（Phase 3→4）
- [ ] **Response metadata extraction**: トークンレスポンスから実際の有効期限を抽出
- [ ] **Explicit authentication check**: 構成ファイル/パラメータからの直接認証情報取得オプション（低優先度）
- [ ] **テスト**: 全機能のテストをパスさせる（80+ tests）

## アプローチ

### 優先度別実装順序

1. **HIGH（ドキュメント）**: ユーザーが最初に必要な情報を確実に提供
   - README.md: プロジェクト概要、インストール、クイックスタート
   - docs/quickstart.md: 実行可能な使用例
   - docs/api_reference.md: API仕様書
   - docs/google_setup.md: Google Console設定手順

2. **MEDIUM（システム時刻統合）**: Phase 4 で実装可能な主要機能
   - token_manager.mbt に Unix timestamp サポートを追加
   - 既存の offset ベース API は互換性維持
   - get_unix_timestamp(), system_time_offset() などのヘルパー関数

3. **MEDIUM（レスポンスメタデータ抽出）**: Token Manager との連携
   - google_api_client.mbt で実際の expires_in を使用
   - Token エンドポイントレスポンス構造体の定義

4. **LOW（明示的認証チェック）**: 設定管理機能
   - google_auth_client.mbt に設定ファイル読み込みオプション追加
   - 既存の ADC/Metadata Server フローとの優先度管理

## スコープ

### 含む
- 全ドキュメント（README、quickstart、API、設定ガイド）
- System time integration（unix timestamp ベース）
- Response metadata 抽出ロジック
- 設定ファイルからの認証情報読み込みオプション
- テスト（80+ tests 維持）

### 含まない
- HTTP クライアント統合（Client Credentials, Metadata Server実装）- 別フェーズ
- RSA署名実装 - 依存ライブラリ待ち
- E2E テスト（複数GCP環境）- Phase 5以降

## 影響範囲

| ファイル | 変更内容 | テスト影響 |
|---------|---------|----------|
| `README.md` | 新規作成 - プロジェクト概要、インストール、使用例 | N/A |
| `docs/quickstart.md` | 新規作成 - ステップバイステップガイド | N/A |
| `docs/api_reference.md` | 新規作成 - API仕様（自動生成可能） | N/A |
| `docs/google_setup.md` | 新規作成 - Google Console設定手順 | N/A |
| `lib/token_manager.mbt` | Unix timestamp メソッド追加 | 17 tests → 20+ tests |
| `lib/google_api_client.mbt` | Response metadata 抽出ロジック追加 | 12 tests → 15+ tests |
| `lib/google_auth_client.mbt` | 明示的認証チェックオプション追加 | 2 tests → 3+ tests |
| `lib/token_manager_test.mbt` | Unix timestamp テスト追加 | +3 tests |
| `lib/google_api_client_test.mbt` | Response metadata テスト追加 | +3 tests |
| `lib/google_auth_client_test.mbt` | 明示的認証チェックテスト追加 | +1 test |

## 実装計画

### Step 1: Documentation 作成（2-3時間）
- README.md: プロジェクト概要、セットアップ、基本使用例
- docs/quickstart.md: 実行可能なステップバイステップガイド
- docs/api_reference.md: 自動生成または手書き仕様書
- docs/google_setup.md: Google OAuth2 プロジェクト設定手順

### Step 2: Token Manager に Unix Timestamp サポート追加（1-2時間）
```moonbit
// 追加メソッド
pub fn TokenManager::from_unix_timestamp(
  access_token: String,
  expires_in: Int,
  issued_at_timestamp: Int,  // Unix epoch 秒
  token_type: String
) -> TokenManager

pub fn TokenManager::get_issued_at_timestamp(self: TokenManager) -> Int?
```

テスト追加:
- Unix timestamp の expiry チェック
- Offset ベースとの互換性確認
- システム時刻との連携

### Step 3: Google API Client で Response Metadata 抽出（1-2時間）
```moonbit
// TokenResponse 構造体定義
pub struct TokenResponse {
  access_token: String
  expires_in: Int
  token_type: String
}

// 更新: authenticate() で実際の expires_in を使用
// Phase 2 では固定値 3600、Phase 4 ではレスポンスから取得
```

テスト追加:
- レスポンスメタデータの抽出確認
- 異なる expires_in 値の処理

### Step 4: 明示的認証情報チェック追加（30分-1時間）
```moonbit
// google_auth_client.mbt に追加
pub fn new_auth_client_with_explicit_credentials(
  credentials: ServiceAccountCredentials
) -> GoogleAuthClient

// or パラメータ化オプション
pub fn new_auth_client_with_config(
  explicit_creds: ServiceAccountCredentials?
) -> GoogleAuthClient
```

テスト追加:
- 明示的認証情報の優先度確認（ADC より前）
- フォールバック動作確認

## テスト戦略

- 既存 80 tests + 新規 7-10 tests = 87-90 tests
- 全機能について offset ベースとの互換性確認
- System time integration の独立性確認（offset ベースは廃止しない）

## リスク・対策

| リスク | 対策 |
|--------|------|
| Documentation の不完全性 | ユーザーテスト用 examples/ 充実度確認 |
| Unix timestamp 統合での既存 API 破壊 | Offset ベース API は互換性維持、新メソッド追加方式 |
| Metadata extraction で無効なレスポンス処理 | エラーハンドリング強化、デフォルト値設定 |
| 設定ファイル読み込みの依存性 | 既存の load_credentials_from_env() との優先度明確化 |

## 検証方法

```bash
moon test           # 90+ tests パス確認
moon fmt lib        # コード整形確認
moon info lib       # インターフェース更新
```

ドキュメント検証:
- README が初心者向けか
- quickstart.md が実行可能か
- API reference の完全性

---

**Next Phase**: HTTP クライアント統合により、Client Credentials Flow と Metadata Server 実装（Phase 5）
