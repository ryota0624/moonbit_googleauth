# Steering: Phase 1.5 - Server-to-Server認証実装

## 目的・背景

Phase 1では認可コードフロー（ユーザーの同意が必要）を実装しました。Phase 1.5では、ユーザーの介入なしにアクセストークンを取得する**サーバー間認証**を実装します。

これにより以下のシナリオに対応：
- クラウド環境（GCP、Google Cloud Run）での認証
- バッチ処理やバックエンドサービスの認証
- マイクロサービス間の通信

## ゴール

Phase 1.5完了時点で以下が達成される状態：

1. ✅ Client Credentials Flow（Google特有のラッパー）
2. ✅ Application Default Credentials (ADC) 対応
3. ✅ Metadata Server 認証（GCE/GKE/Cloud Run用）
4. ✅ 自動認証検出機能
5. ✅ (条件付き) Service Account JWT署名

## アプローチ

### 優先度と実装順序

**高優先度（必須）:**
1. Application Default Credentials (ADC) - JSON keyファイル解析
2. Metadata Server認証 - クラウド環境用
3. 自動認証検出 - これらの統合

**中優先度（推奨）:**
4. Client Credentials Flow ラッパー
5. RSA暗号化ライブラリ調査

**低優先度（オプション）:**
6. Service Account JWT実装 - 暗号ライブラリ依存

### 実装パターン

```
┌────────────────────────────────────────────┐
│ Google Auth Client                         │ ← 自動検出
│ (auto_detect_and_authenticate)             │
├────────────────────────────────────────────┤
│                                            │
├─ ADC (環境変数)                           │ Step 1
│  → GOOGLE_APPLICATION_CREDENTIALS          │
│  → JSON keyファイル解析                    │
│                                            │
├─ Metadata Server                          │ Step 2
│  → http://metadata.google.internal        │
│  → GCE/GKE/Cloud Run環境                  │
│                                            │
├─ Client Credentials Flow                  │ Step 3
│  → (明示的に指定された場合)                │
│                                            │
└────────────────────────────────────────────┘
```

## スコープ

### 含む ✅

**Phase 1.5.1: Application Default Credentials（1-2日）**
- JSON Service Account keyファイル解析
- GOOGLE_APPLICATION_CREDENTIALS環境変数対応
- Service Account credentials構造体

**Phase 1.5.2: Metadata Server（1日）**
- Metadata Server エンドポイントアクセス
- タイムアウト処理（1秒）
- GCP環境検出

**Phase 1.5.3: 自動認証検出（1-2日）**
- 複数認証方法の自動選択
- フォールバック処理
- E2Eテスト

### 含まない ❌

- Service Account JWT署名（RSA暗号ライブラリがない場合）
- OAuth 2.0 Device Authorization Flow
- Token Introspection/Revocation
- 暗号ライブラリ実装（既存ライブラリ利用）

## 影響範囲

### 新規ファイル

```
lib/
├── google_client_credentials.mbt       # Client Credentials
├── google_client_credentials_test.mbt
├── service_account/
│   ├── adc.mbt                         # ADC実装
│   ├── adc_test.mbt
│   ├── metadata.mbt                    # Metadata Server
│   ├── metadata_test.mbt
│   └── types.mbt                       # 共通型定義
├── google_auth_client.mbt              # 自動認証検出
└── google_auth_client_test.mbt
```

### 既存ファイル影響

- `moon.mod.json` - 新規依存関係の追加可能性
- `lib/moon.pkg.json` - モジュール設定更新

## 技術的な決定事項

### 1. JSON パース

MoonBitビルトインのJSON機能を使用（外部依存なし）

### 2. HTTP通信

`ryota0624/oauth2` に含まれるHTTPクライアントを再利用

### 3. エラーハンドリング

各認証方法で独立したエラー型を定義：
- `AdcError` - ADC関連
- `MetadataError` - Metadata Server関連

### 4. タイムアウト戦略

Metadata Server チェック時、1秒のタイムアウトを設定（環境外の場合の高速フェイルオーバー）

## 実装詳細

### Phase 1.5.1: Application Default Credentials

**主要な型:**
```moonbit
pub struct ServiceAccountCredentials {
  type : String
  project_id : String
  private_key_id : String
  private_key : String
  client_email : String
  client_id : String
  auth_uri : String
  token_uri : String
}

pub enum AdcError {
  EnvironmentVariableNotSet
  FileNotFound(String)
  InvalidJson(String)
  MissingField(String)
}
```

**主要な関数:**
```moonbit
pub fn load_credentials_from_env() -> Result[ServiceAccountCredentials, AdcError]
pub fn parse_service_account_key(json: String) -> Result[ServiceAccountCredentials, AdcError]
```

### Phase 1.5.2: Metadata Server

**主要な型:**
```moonbit
pub struct MetadataServerConfig {
  base_url : String
  timeout_ms : Int
}

pub enum MetadataError {
  Unavailable
  InvalidResponse(String)
  HttpError(Int, String)
  Timeout
}
```

**主要な関数:**
```moonbit
pub fn is_metadata_server_available() -> Bool
pub fn get_token_from_metadata_server() -> Result[String, MetadataError]
```

### Phase 1.5.3: 自動認証検出

**主要な型:**
```moonbit
pub enum AuthCredentials {
  ServiceAccount(ServiceAccountCredentials)
  MetadataServer(MetadataServerConfig)
  ClientCredentials(String, String, String)
}

pub struct GoogleAuthClient {
  credentials : AuthCredentials
}
```

**主要な関数:**
```moonbit
pub fn auto_detect_and_authenticate() -> Result[GoogleAuthClient, String]
pub fn get_access_token(client: GoogleAuthClient) -> Result[String, String]
```

## テスト戦略

### ユニットテスト

1. **ADC テスト**
   - 有効なJSON keyのパース
   - 無効なJSONの処理
   - 必須フィールド検証
   - 環境変数なしのエラー処理

2. **Metadata Server テスト**
   - 利用可能状態の検出
   - タイムアウト処理
   - レスポンスパース

3. **自動認証検出テスト**
   - 各方法の優先順位
   - フォールバック動作
   - エラーハンドリング

### 統合テスト

- ローカル環境（ADC）での動作確認
- （オプション）GCP環境での動作確認

## 成功基準

- ✅ 全ユニットテスト成功
- ✅ 複数の認証方法をサポート
- ✅ エラーハンドリングが包括的
- ✅ コード品質チェック実施
- ✅ ドキュメント完備

## 見積もり

| フェーズ | 工数 | 依存関係 |
|---------|------|--------|
| Phase 1.5.1 (ADC) | 3-5時間 | JSON パース機能 |
| Phase 1.5.2 (Metadata) | 3-4時間 | HTTP機能 |
| Phase 1.5.3 (自動検出) | 3-5時間 | 1.5.1, 1.5.2 |
| 暗号ライブラリ調査 | 1時間 | - |
| JWT実装（条件付き） | 4-6時間 | RSA暗号ライブラリ |
| **合計** | **14-25時間** | **見積もり: 2-3日** |

## リスクと軽減策

### リスク1: JSON パース複雑性

**リスク:** Service Account key ファイルの複雑なJSON構造のパース
**軽減策:** MoonBitのビルトインJSON機能の十分な検証、フィールド検証の厳密化

### リスク2: Metadata Server タイムアウト

**リスク:** Metadata Serverチェックで長時間ハング
**軽減策:** 1秒のタイムアウト設定、非同期処理の検討

### リスク3: RSA暗号ライブラリの不在

**リスク:** JWT署名に必要なRSA暗号ライブラリがない
**軽減策:** 条件付き実装、ADC/Metadata Serverで代替可能

## 参考資料

- `docs/server_to_server_auth.md` - Server-to-Server認証概要
- `docs/application_default_credentials.md` - ADC詳細
- [Google Cloud の認証](https://cloud.google.com/docs/authentication)
- [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
- [Metadata Server](https://cloud.google.com/docs/authentication/gce)
