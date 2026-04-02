# 完了報告: authorized_user ADCサポートの追加

## 実装内容

Google公式SDKのADCフローに準拠し、`gcloud auth application-default login` で生成される `authorized_user` 型の認証情報をサポートした。

### ADCフローの拡張

変更前:
1. `GOOGLE_APPLICATION_CREDENTIALS` 環境変数 (service_account のみ)
2. メタデータサーバー

変更後:
1. `GOOGLE_APPLICATION_CREDENTIALS` 環境変数 (service_account **および** authorized_user)
2. Well-known location (`~/.config/gcloud/application_default_credentials.json`)
3. メタデータサーバー

### 主要な変更点

- `AuthorizedUserCredentials` struct の追加 (type_, client_id, client_secret, refresh_token)
- `AuthCredentialsType` enum に `AuthorizedUser` variant を追加
- `AdcError` enum に `UnsupportedCredentialType`, `WellKnownLocationNotFound` variant を追加
- JSON内の `"type"` フィールドによる認証情報タイプの自動検出
- Well-known location のプラットフォーム別パス解決 (macOS/Linux: HOME, Windows: APPDATA)
- `auto_detect_and_authenticate()` のフローを3段階に拡張
- `get_access_token()` に `AuthorizedUser` の match arm を追加（スタブ）

## 技術的な決定事項

- **コンストラクタ関数の追加**: `new_authorized_user_credentials()` — blackboxテストからstruct を構築するために必要
- **JSON二重パース**: `detect_credential_type()` でtype検出後、専用パーサーで再パース。認証情報ファイルは小さく起動時1回のみなのでパフォーマンス影響なし
- **トークン交換はスタブ**: `exchange_refresh_token()` はHTTPクライアント未実装のためスタブ。コメントでPOSTパラメータを記載
- **既存API互換**: `load_credentials_from_file()` は変更せず、新規に `load_and_detect_credentials_from_file()` を追加

## 変更ファイル一覧

- 変更:
  - `lib/service_account_types.mbt`: AuthorizedUserCredentials struct, AuthCredentialsType に AuthorizedUser, AdcError に2 variant追加
  - `lib/service_account_adc.mbt`: 8関数追加 (detect_credential_type, parse_authorized_user_key, new_authorized_user_credentials, get_well_known_credentials_path, load_and_detect_credentials_from_file, load_json_from_well_known_location, validate_authorized_user_credentials, exchange_refresh_token)
  - `lib/google_auth_client.mbt`: struct にauthorized_userフィールド追加, new_auth_client_from_authorized_user追加, auto_detect_and_authenticate を3段階ADCフローに更新, get_access_token に AuthorizedUser arm追加
  - `lib/service_account_adc_test.mbt`: 10件のテスト追加
  - `lib/google_auth_client_test.mbt`: 2件のテスト追加
  - `lib/pkg.generated.mbti`: moon info で自動更新
- 追加:
  - `docs/steering/20260402_authorized_user_adc.md`: Steeringドキュメント
  - `docs/completed/20260402_authorized_user_adc.md`: 本ドキュメント

## テスト

- 全110テストパス (既存80件から30件増加は過去フェーズの追加分含む + 今回12件追加)
- 新規テスト内訳:
  - `parse_authorized_user_key`: 正常系、空JSON、client_id欠損、refresh_token欠損 (4件)
  - `detect_credential_type`: service_account、authorized_user、typeなし (3件)
  - `validate_authorized_user_credentials`: 正常系、空refresh_token (2件)
  - `get_well_known_credentials_path`: パス含有確認 (1件)
  - `new_auth_client_from_authorized_user`: 構築確認 (1件)
  - `new_auth_client`: authorized_user が None (1件)
- 動作確認: `moon test` で全テスト実行可能

## 今後の課題・改善点

- [ ] HTTPクライアント実装後に `exchange_refresh_token()` を実装（refresh_token → access_token交換）
- [ ] `quota_project_id` フィールドの対応（一部のADC JSONに含まれる）
- [ ] `CLOUDSDK_CONFIG` 環境変数による gcloud 設定ディレクトリのカスタマイズ対応
- [ ] Windows環境でのパステスト

## 参考資料

- [Google ADC公式ドキュメント](https://cloud.google.com/docs/authentication/application-default-credentials)
- [gcloud auth application-default login](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)
