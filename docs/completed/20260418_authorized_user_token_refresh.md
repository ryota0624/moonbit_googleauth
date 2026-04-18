# 完了報告: AuthorizedUser トークンリフレッシュ実装

## 実装内容

`lib/google_auth_client.mbt:170` の `get_access_token()` 内 `AuthorizedUser` ブランチで `InvalidCredentials("AuthorizedUser token refresh not implemented yet")` を返していたスタブを、既に完全実装済みの `exchange_refresh_token()` に接続した。これにより、ADC (`gcloud auth application-default login`) で生成された authorized_user 認証情報を `GoogleApiClient::authenticate()` から使えるようになった。

## 技術的な決定事項

1. **async 伝播の範囲を最小限に** — `get_access_token`, `GoogleApiClient::authenticate`, `GoogleApiClient::refresh_token_if_needed` の 3 関数のみを `async fn` 化。`MetadataServer` ブランチは同期呼び出しのまま async 関数内で使える（無害）ため触らない。

2. **エラーマッピングは string interpolation** — `AdcError` は `derive(Show)` 済みだが、既存コードで `.to_string()` は例外型専用の呼び出しパターンだった。`"\{err}"` 形式（`Show` trait 経由の文字列化）で `AuthenticationError::InvalidCredentials(String)` に包むことで、新バリアントを追加せず既存パターンに合わせた。

3. **expires_in は 3600 秒固定を踏襲** — `exchange_refresh_token` のレスポンス解析を拡張して `expires_in` を抽出することも可能だったが、Phase 4 の `TokenResponse` 統合で扱う別スコープとして本作業では触らない。

4. **テスト追加なし** — プロジェクト全体で `async test` は未サポート扱い（既存 `*_test.mbt` に「placeholder for Phase 3 when async test support is available」のコメントが 10 箇所）。本件もハッピーパス (実 HTTP 必要) と防御的エラーパス (async 呼び出し必要) とも追加せず、既存の placeholder 方針を踏襲した。

## 変更ファイル一覧

### 変更
- `lib/google_auth_client.mbt`
  - `get_access_token` に `async` 付与
  - `AuthorizedUser` ブランチで `exchange_refresh_token(creds)` を呼び出す本実装に置換
- `lib/google_api_client.mbt`
  - `GoogleApiClient::authenticate` に `async` 付与
  - `GoogleApiClient::refresh_token_if_needed` に `async` 付与
- `lib/pkg.generated.mbti`
  - `moon info` による自動更新（3 関数の `async` シグネチャ反映、計 3 行差分）

### 追加
- `docs/steering/20260418_authorized_user_token_refresh.md`
- `docs/completed/20260418_authorized_user_token_refresh.md`

## テスト

- **実行**: `moon test`
- **結果**: 110 tests passed, 0 failed
- **カバレッジ**: 既存テストを維持。新規テストは追加せず（理由は技術的決定事項 4 を参照）
- **動作確認**:
  - `moon fmt`: 差分なし（整形済み状態）
  - `moon info`: `.mbti` の差分は 3 関数の `async` 付与のみ（計画どおり）
  - スタブ文字列 `"AuthorizedUser token refresh not implemented yet"` が `.mbt` ソースから消失したことを Grep で確認
  - `cmd/main/main.mbt` は `exchange_refresh_token` を直接呼んでおり影響なし（既存動作継続）

## 今後の課題・改善点

- [ ] `ServiceAccount` ブランチの実装（JWT 署名が必要、Phase 4+）
- [ ] `TokenResponse` / `expires_in` の動的抽出（Phase 4 の `TokenResponse` 統合で対応）
  - 現状は 3600 秒固定
- [ ] 実 HTTP を叩く統合テスト（モックサーバー or テスト用 fake）
- [ ] `async test` サポートが入った際、placeholder 化されたテストの本実装化
- [ ] `derive(Show)` 非推奨警告の対応（`service_account_types.mbt:48`、本件スコープ外）

## 参考資料

- Steering: `docs/steering/20260418_authorized_user_token_refresh.md`
- Plan: `/Users/ryota.suzuki/.claude/plans/invalidcredentials-authorizeduser-token-bubbly-tome.md`
- 先行作業: `docs/steering/20260402_authorized_user_adc.md`
- 関連実装: `lib/service_account_adc.mbt:342` `exchange_refresh_token`
