# Steering: AuthorizedUser トークンリフレッシュ実装

## 目的・背景

`lib/google_auth_client.mbt:197-207` の `get_access_token()` 内 `AuthorizedUser` ブランチは、`InvalidCredentials("AuthorizedUser token refresh not implemented yet")` を返すスタブのままになっている。

一方、`lib/service_account_adc.mbt:342-385` の `exchange_refresh_token()` は `https://oauth2.googleapis.com/token` への `application/x-www-form-urlencoded` POST、`access_token` 抽出まで完全実装済みで、`cmd/main/main.mbt:50` からは既に直接呼び出されて動作している。つまり「下層はできているが、高レベル API (`GoogleApiClient::authenticate`) からつながっていない」状態。

本作業では、この未接続の部分を埋め、ADC (`gcloud auth application-default login`) で生成された authorized_user 認証を `GoogleApiClient::authenticate` で使えるようにする。

既存 `docs/steering/20260402_authorized_user_adc.md` の続編にあたる。

## ゴール

- `get_access_token()` の `AuthorizedUser` ブランチが `exchange_refresh_token()` を呼び出し、実アクセストークンを返す
- `GoogleApiClient::authenticate()` が authorized_user な `GoogleAuthClient` で正しく動く
- `"AuthorizedUser token refresh not implemented yet"` 文字列がコードから消える
- 既存 80+ テストは pass を維持

## アプローチ

1. **`get_access_token` を `pub async fn` に変更** — 既存 async な `exchange_refresh_token` を呼ぶため
2. **async の伝播** — `GoogleApiClient::authenticate` と `GoogleApiClient::refresh_token_if_needed` も `pub async fn` 化
3. **エラーマッピング** — `AdcError` は string interpolation `"\{err}"` で `AuthenticationError::InvalidCredentials(String)` に包む（既存パターン踏襲、新バリアント追加なし）
4. **テスト** — 既存 async 化された関数を呼ぶ 2 テストは placeholder に置き換える（プロジェクト全体で `async test` は未サポート扱い）

## スコープ

### 含む

- `lib/google_auth_client.mbt` の `get_access_token` async 化 + `AuthorizedUser` ブランチ本実装
- `lib/google_api_client.mbt` の `authenticate` / `refresh_token_if_needed` async 化
- `lib/google_api_client_test.mbt` の該当テスト 2 件の placeholder 化
- `.mbti` 更新、`moon fmt`、`moon test` パス確認
- 完了ドキュメント作成

### 含まない

- `ServiceAccount` ブランチ（JWT 署名が未実装、Phase 4+ 扱い）
- `TokenResponse` / `expires_in` の動的抽出（Phase 4 の `TokenResponse` 統合で扱う別スコープ）
- 実 HTTP を叩く統合テスト
- `exchange_refresh_token` 自体の改修

## 影響範囲

| ファイル | 変更内容 |
|---|---|
| `lib/google_auth_client.mbt` | `get_access_token` に `async` 付与、`AuthorizedUser` ブランチ本実装 |
| `lib/google_api_client.mbt` | `authenticate` / `refresh_token_if_needed` に `async` 付与 |
| `lib/google_api_client_test.mbt` | 該当 2 テストを placeholder 化 |
| `lib/pkg.generated.mbti` | `moon info` による自動更新（`async` 付与に伴う差分） |

**他機能への影響**:
- `cmd/main/main.mbt` は `exchange_refresh_token` を直接呼んでおり影響なし
- `get_access_token` / `authenticate` の呼び出し元は Grep で上記以外存在しないことを確認済み
- `MetadataServer` ブランチは async 関数内で同期呼び出しのまま使える（無害）
