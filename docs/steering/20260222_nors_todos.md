# Steering: RSA非依存TODOの対応

## 目的・背景

Todo.md に記録されたPhase 2以前の残存TODOのうち、RSA署名ライブラリに依存しないものを実装する。
現在78テストが全てパス。新規コードはこの状態を維持する必要がある。

**スキップ理由：**
- `google_client_credentials.mbt` - JWT + RS256署名が必要（RSA依存）
- `google_auth_client.mbt` のServiceAccountトークン取得 - 同上（RSA依存）
- `service_account_metadata.mbt` の Metadata Server - async HTTP呼び出しが必要（リスク大）
- `load_credentials_from_file()` - ファイルI/Oは非同期のみ（MoonBitの制約）
- `FileTokenStorage::save/load/clear` - ファイルI/O（MoonBitの制約）

## ゴール

Phase 2以前の残存TODOのうち実装可能な部分を完成させる：

1. ✅ `parse_service_account_key()` の完全JSONパース（モック→実JSON値取得）
2. ✅ `load_credentials_from_env()` - 環境変数読み込み実装（スタブ）

## アプローチ

### 1. parse_service_account_key() の改善

**実装内容：**
- `@json.parse()` で実際のフィールド値を取得
- 8つの必須フィールド（type, project_id, private_key_id, private_key, client_email, client_id, auth_uri, token_uri）を検証
- 2つのオプションフィールド（auth_provider_x509_cert_url, client_x509_cert_url）を取得

**ファイル：** `lib/service_account_adc.mbt`

### 2. load_credentials_from_env() のスタブ化

**実装内容：**
- 環境変数アクセスライブラリが利用可能になるまでスタブを提供
- EnvironmentVariableNotSet を返す（現在と同じ）

**ファイル：** `lib/service_account_adc.mbt`

### 3. テストの更新

**実装内容：**
- parse_service_account_key() のテストJSONに不足フィールドを補完
- テストの期待値を実JSON解析結果に更新

**ファイル：** `lib/service_account_adc_test.mbt`

## スコープ

### 含むもの
- parse_service_account_key() の完全実装
- サービスアカウントJSONの完全パース
- テストの完全カバレッジ

### 含まないもの
- ファイルI/O実装（MoonBit非同期制約のため Phase 3対象）
- 環境変数アクセス実装（ライブラリ統合待ち）
- RSA署名・JWT実装（RSAライブラリ開発中）
- async HTTP（リスク大）

## 影響範囲

- 変更ファイル：
  - `lib/service_account_adc.mbt` - 2つの関数を実装
  - `lib/service_account_adc_test.mbt` - テストJSONを補完

- テスト：78テスト全てパス（新規コードで変更なし）

- 依存関係：
  - `moon.mod.json`, `lib/moon.pkg` - 変更なし（ファイルI/O非実装のため）

## 技術的決定

1. **JSONパース戦略:** @json.parse() + マッチング（MoonBit標準）
2. **エラーハンドリング:** Result型で一貫（既存パターン）
3. **ファイルI/O:** Phase 3に延期（MoonBitの非同期制約）
4. **環境変数アクセス:** スタブ化（ライブラリ統合待ち）

## 検証方法

```bash
# 全テスト実行
moon test

# フォーマット確認
moon fmt lib

# インターフェース更新
moon info lib
```

期待される結果：
- 78テスト全てパス
- コンパイルエラーなし
- 警告なし（redundant_modifierは既存）
