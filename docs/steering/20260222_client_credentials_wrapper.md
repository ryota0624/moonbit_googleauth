# Steering: Client Credentials Flow ラッパー

## 目的・背景

既存のryota0624/oauth2ライブラリはクライアント認証情報フロー（Client Credentials Flow）を実装していますが、Google固有の設定やエラーハンドリングを統一するため、Googleラッパーを作成する必要があります。

これにより、Service Account認証でのServer-to-Server通信が可能になります。

## ゴール

- GoogleClientCredentials構造体でGoogle固有の設定を定義
- ryota0624/oauth2ライブラリとの統合
- get_access_token()メソッドでトークン取得を簡潔に
- 適切なエラーハンドリング

## アプローチ

### 実装パターン
- `google_client_credentials.mbt`: メイン実装
  - `GoogleClientCredentials` struct
    - service_account_email: Service Account のメールアドレス
    - token_uri: トークン取得エンドポイント
    - client_id: クライアントID
    - private_key: 秘密鍵（PEM形式）
  - `get_access_token()` 関数
    - ryota0624/oauth2のClientCredentialsを使用
    - Google OAuth2トークンエンドポイントに対応

- `google_client_credentials_test.mbt`: テスト
  - 構造体の初期化
  - トークン取得（モック/エラーシナリオ）
  - エラーハンドリング

## スコープ

**含む:**
- GoogleClientCredentials構造体の定義
- get_access_token()の実装
- ユニットテスト

**含まない:**
- 実際のHTTP通信（Phase 2で実装）
- トークンキャッシング
- リフレッシュロジック

## 影響範囲

- 新規ファイル:
  - `lib/google_client_credentials.mbt`
  - `lib/google_client_credentials_test.mbt`

- 既存ファイル参照:
  - `lib/service_account_types.mbt` (エラー型)
  - `ryota0624/oauth2` 外部ライブラリ

## 技術的なポイント

1. **型安全性**: ServiceAccountCredentialsから必要なフィールドを抽出
2. **ラッパー設計**: oauth2ライブラリの複雑性を隠蔽
3. **エラー統一**: ClientCredentialsErrorで一貫したエラーハンドリング
4. **将来拡張性**: Phase 2でのトークンキャッシング機能を見据えた設計

## 参考資料

- Todo.md: Phase 1.5.4の詳細
- docs/server_to_server_auth.md: Server-to-Server認証仕様
- Google OAuth2 認証コード: https://developers.google.com/identity/protocols/oauth2/service-account
