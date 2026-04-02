# Steering: authorized_user ADCサポートの追加

## 目的・背景

現在のADC (Application Default Credentials) 実装は `GOOGLE_APPLICATION_CREDENTIALS` 環境変数（service_account型のみ）とメタデータサーバーの2段階のみ対応している。

`gcloud auth application-default login` コマンドで生成される `authorized_user` 型の認証情報に未対応であり、ローカル開発環境で最も一般的な認証フローが使えない状態。Google公式SDKのADCフローに準拠するため、well-known locationの探索と `authorized_user` 型の認証情報サポートを追加する。

## ゴール

- Google公式ADCフローに準拠した3段階の認証検出:
  1. `GOOGLE_APPLICATION_CREDENTIALS` 環境変数（service_account / authorized_user 両対応）
  2. Well-known location (`~/.config/gcloud/application_default_credentials.json`)
  3. メタデータサーバー
- `authorized_user` 型のJSONパースとバリデーション
- refresh tokenによるトークン交換のスタブ（HTTPクライアント未実装のため）
- 既存テストが壊れないこと

## アプローチ

1. `AuthorizedUserCredentials` struct を新規追加
2. `AuthCredentialsType` enum に `AuthorizedUser` variant を追加
3. `detect_credential_type()` でJSON内の `"type"` フィールドを検出し、適切なパーサーにルーティング
4. `get_well_known_credentials_path()` でプラットフォーム別のパスを返す
5. `auto_detect_and_authenticate()` のフローを3段階に拡張
6. `get_access_token()` に `AuthorizedUser` の match arm を追加（スタブ）

## スコープ

### 含む
- `AuthorizedUserCredentials` struct と関連型
- `authorized_user` JSONパーサー
- Well-known locationの探索
- `auto_detect_and_authenticate()` のフロー拡張
- `GOOGLE_APPLICATION_CREDENTIALS` での authorized_user 型サポート
- バリデーション関数
- トークン交換スタブ (`exchange_refresh_token`)
- ユニットテスト（12件程度）

### 含まない
- 実際のHTTPリクエストによるトークン交換（HTTPクライアント未実装）
- `quota_project_id` 等の追加フィールド対応
- トークンキャッシュの永続化

## 影響範囲

| ファイル | 変更内容 |
|---------|---------|
| `lib/service_account_types.mbt` | 新struct, enum variant追加 |
| `lib/service_account_adc.mbt` | 7関数追加 |
| `lib/google_auth_client.mbt` | struct更新, constructor追加, auto_detect/get_access_token更新 |
| `lib/service_account_adc_test.mbt` | テスト10件追加 |
| `lib/google_auth_client_test.mbt` | テスト2件追加 |
| `lib/pkg.generated.mbti` | moon info で自動更新 |
