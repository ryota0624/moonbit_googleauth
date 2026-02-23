# Steering: プロジェクト全体のasync化 + 遅延機能実装

## 目的・背景

MoonBitにおいて、ファイルI/O（`mizchi/x/fs`）とシステム操作（`mizchi/x/sys`）は全て async 関数です。現在のプロジェクトは同期関数のみで実装されているため、以下の機能がスタブ化されています：

- `load_credentials_from_file()` / `load_credentials_from_env()`
- `FileTokenStorage::save/load/clear`

これらを実装するため、プロジェクト全体を async 化し、スタブ化された機能を実装します。

## ゴール

1. **ファイルI/O実装**: 外部ライブラリ `mizchi/x/fs` を使用したファイルベーストークン永続化を実装
2. **環境変数支援**: `mizchi/x/sys` を使用した環境変数読み込みを実装
3. **async化の完全性**: 依存関数を連鎖的にasync化
4. **テスト維持**: 現在の78テストすべてをパスさせ、新規テスト5件追加（計80+テスト）

## アプローチ

### 技術的アプローチ

1. **ボトムアップasync化**: 最下層の I/O 操作から開始し、依存関数を順次async化
   - Layer 1: `load_credentials_from_file()`, `FileTokenStorage` I/Oメソッド
   - Layer 2: `auto_detect_and_authenticate()`, `GoogleAuthClient::get_access_token()`
   - Layer 3: `GoogleApiClient` の authenticate/refresh メソッド

2. **ライブラリ統合**:
   - `mizchi/x/fs`: ファイル読み書き（`read_file`, `write_file`, `exists`）
   - `mizchi/x/sys`: 環境変数取得（`get_env_var`）
   - `@json.parse()`: すでに使用中、JSON deserialize

3. **エラーハンドリング**: `try { ... } catch { Error => ... }` パターンで IOError を AdcError/TokenStorageError に変換

### 実装の段階

| 段階 | 対象ファイル | 内容 |
|------|------------|------|
| 1 | moon.mod.json, lib/moon.pkg | 依存関係追加 |
| 2 | service_account_adc.mbt | 2関数のasync化+実装 |
| 3 | token_storage.mbt | FileTokenStorage 3関数のasync化+実装 |
| 4 | google_auth_client.mbt, google_api_client.mbt | 5関数のasync化（本体変更なし） |
| 5 | テストファイル | async test への変換・追加 |

## スコープ

### 含む

- ✅ `mizchi/x/fs` と `mizchi/x/sys` の統合
- ✅ スタブ化された3機能の完全実装
- ✅ 連鎖的なasync化（5個の公開関数）
- ✅ 既存テスト78件の async test 変換・保証
- ✅ 新規テスト5件の追加（FileTokenStorage, load_credentials_from_*）

### 含まない

- ❌ システムタイムスタンプの統合（Phase 4対象）
- ❌ シリアライゼーション最適化（@json ライブラリのみ使用）
- ❌ error enum の大規模な再設計
- ❌ サンプル・ドキュメント実装

## 影響範囲

### 変更ファイル（11ファイル）

**設定ファイル:**
- `moon.mod.json`: deps に `"mizchi/x": "0.1.3"` 追加
- `lib/moon.pkg`: imports に `"mizchi/x/fs"`, `"mizchi/x/sys"` 追加

**実装ファイル:**
- `lib/service_account_adc.mbt`: `load_credentials_from_file()`, `load_credentials_from_env()` を async化+実装
- `lib/token_storage.mbt`: `FileTokenStorage` 3関数 (save/load/clear) を async化+実装
- `lib/google_auth_client.mbt`: 2関数を async化（本体変更なし）
- `lib/google_api_client.mbt`: 3関数を async化（本体変更なし）

**テストファイル:**
- `lib/service_account_adc_test.mbt`: async test 2件追加
- `lib/token_storage_test.mbt`: スタブテスト3件削除、async test 3件追加
- `lib/google_auth_client_test.mbt`: test → async test 変換（3件）
- `lib/google_api_client_test.mbt`: test → async test 変換（2件）

**ドキュメント:**
- `docs/steering/20260223_async_migration.md`: このドキュメント
- `docs/completed/20260223_async_migration.md`: 完了報告書（実装後）

### 影響を受けるコンポーネント

- **公開API**: `load_credentials_from_*`, `FileTokenStorage::*` がasync化 → ユーザーコードで await 必須
- **内部API**: `google_auth_client.mbt`, `google_api_client.mbt` がasync化 → 呼び出し側で await 必須
- **テストスイート**: 80+テストが全てパス状態を維持

## 技術的な決定事項

1. **`write_file` のシグネチャ対応**: `write_file(path: StringView, data: &@io.Data)` の第2引数
   - MoonBitの String には自動変換が期待される、またはコンパイルエラー時は `@io` 変換関数を調査

2. **ファイル存在確認**: `clear()` 実装で `@fs.exists()` を使用し、不要な write を防止

3. **エラー分岐**: `load()` で JSON parse 失敗時 → `DeserializationError`、ファイル未存在時 → `NotFound`

4. **immutability維持**: FileTokenStorage に state 変更なし（save/load/clear は新インスタンスを返さず Unit を返す）

## テスト戦略

### 削除（スタブ動作確認）

```
token_storage_test.mbt:
  - "file_storage save returns not available error"
  - "file_storage load returns not available error"
  - "file_storage clear returns not available error"
```

### 追加（実装確認）

```
token_storage_test.mbt:
  - "file_storage saves and loads token"
  - "file_storage load returns not found for missing file"
  - "file_storage clear empties file"

service_account_adc_test.mbt:
  - "load_credentials_from_file returns error for nonexistent file"
  - "load_credentials_from_env returns error when not set"
```

### 変換（既存テストのasync化）

```
google_auth_client_test.mbt: 3件
google_api_client_test.mbt: 2件
```

### 期待される結果

- 既存78テスト + 削除-3 + 追加+5 = **80テスト以上すべてパス**
- `moon fmt`, `moon info` で `.mbti` に async 関数マーク付加

## リスク・対策

| リスク | 対策 |
|--------|------|
| write_file 第2引数の型マッチング | コンパイルエラー時、mizchi/x のテストコード参照・@io モジュール調査 |
| clear 後 load 呼び出しで DeserializationError | テストで両エラーを許容 |
| 既存テストのコンパイルエラー | async test パターンに統一、本体は変更なし |
| TokenManager リテラル構築 | 同一パッケージ内で pub なし private フィールドアクセス可能 |

## 成功基準

1. ✅ `moon test` が80+テスト全てパス
2. ✅ `moon fmt` でコード整形完了
3. ✅ `moon info` で `.mbti` 差分確認（async キーワード追加）
4. ✅ git commit で完了報告書を記録
