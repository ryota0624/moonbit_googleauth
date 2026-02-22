# Steering: 自動認証検出機能（Auto-Authentication Detection）

## 目的・背景

Google認証ライブラリのメイン機能として、複数の認証方法を環境に応じて自動的に選択できる統一的なインターフェースが必要です。これにより、ユーザーは環境に合わせて設定を変更することなく、同じコードで動作させることができます。

## ゴール

- GoogleAuthClientの実装により、複数の認証方法を優先度順に試行し、最初に成功した方法を使用する
- フォールバック機構により、ローカル開発、GCP環境、クラウド実行環境での自動切り替えを実現
- 認証失敗時に適切なエラーを返す
- 簡潔なAPI（get_access_token()）でユーザーが認証詳細を気にせずに使用可能

## アプローチ

### 認証優先順位
1. **Explicit Credentials**: ユーザーが明示的に提供した認証情報（将来の拡張）
2. **ADC (Environment Variable)**: `GOOGLE_APPLICATION_CREDENTIALS` 環境変数で指定されたJSONキーファイル
3. **Metadata Server**: GCP環境（GCE, GKE, Cloud Run）で利用可能
4. **エラー**: すべての方法が失敗した場合、適切なエラーを返す

### 実装パターン
- `google_auth_client.mbt`: メイン実装
  - `GoogleAuthClient` struct（認証方法を保持）
  - `AuthCredentialsType` enum（既存のtypesから使用）
  - `auto_detect_and_authenticate()` 関数
  - `get_access_token()` 関数

- `google_auth_client_test.mbt`: テスト
  - 各認証方法の優先順位の検証
  - フォールバック動作
  - エラーハンドリング

## スコープ

**含む:**
- GoogleAuthClientの実装
- auto_detect_and_authenticate()での順序的な試行
- 各認証方法の適切なエラーハンドリング
- ユニットテスト（ローカル環境での検証）

**含まない:**
- 実際のGCP環境での統合テスト（E2E）
- HTTP実装の詳細（Phase 2で実装）
- 環境変数の実際の読み込み（Phase 2で実装）

## 影響範囲

- 新規ファイル:
  - `lib/google_auth_client.mbt`
  - `lib/google_auth_client_test.mbt`

- 既存ファイル参照:
  - `lib/service_account_types.mbt` (AuthCredentialsType enum, エラー型)
  - `lib/service_account_adc.mbt` (ADC関数)
  - `lib/service_account_metadata.mbt` (Metadata Server関数)

- 外部への影響: なし（内部ライブラリの統合レイヤー）

## 実装のポイント

1. **型安全性**: Result型を使用したエラーハンドリング
2. **組み合わせ可能性**: ADCとMetadata Server関数の組み合わせ
3. **テスト容易性**: 各認証方法のモック化が可能な設計
4. **Phase 2との整合性**: 実際のHTTP通信やenv読み込み部分はPhase 2で実装予定

## 参考資料

- Todo.md: Phase 1.5.4の詳細
- docs/application_default_credentials.md: ADC仕様
- docs/server_to_server_auth.md: Metadata Server仕様
