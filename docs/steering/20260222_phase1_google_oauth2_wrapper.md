# Steering: Phase 1 - Google OAuth2 ラッパー実装

## 目的・背景

MoonBit向けのGoogle OAuth2認証ライブラリを実装するため、既存の `ryota0624/oauth2` ライブラリ上に、Google特有の薄いラッパー層を構築する。

当初計画では2-3週間のフルスクラッチ実装を予定していたが、既存ライブラリの発見により、**実装期間を1-2日に短縮**できることが判明した。

## ゴール

Phase 1完了時点で以下が達成される状態：

1. ✅ Google特有の定数定義（エンドポイント、スコープ）の提供
2. ✅ `GoogleOAuth2Client` 構造体とヘルパー関数の実装
3. ✅ 基本的なGoogle OAuth2フロー（認可URL生成→コード交換→トークン取得）が動作
4. ✅ ユニットテストによる動作保証（80%以上のカバレッジ）
5. ✅ サンプルアプリケーション（examples/basic_auth/）の完成
6. ✅ 基本的なドキュメント完備

## アプローチ

**戦略: 薄いラッパー + Google特有機能の提供**

```
┌─────────────────────────────────────────┐
│ googleauth (薄いラッパー：~300行)       │
│ - Google定数（エンドポイント）          │
│ - Googleスコープ定義                    │
│ - GoogleOAuth2Client構造体              │
│ - ヘルパー関数                          │
└─────────────────────────────────────────┘
              ↓ 依存
┌─────────────────────────────────────────┐
│ ryota0624/oauth2 (既存：~2000行)       │
│ - OAuth2プロトコル実装                  │
│ - PKCE/CSRF対応                        │
│ - HTTP通信管理                          │
└─────────────────────────────────────────┘
```

### 実装順序

1. **Google定数定義**（2-3時間）
   - エンドポイント URL定義
   - 一般的なスコープ定数定義
   - ユニットテスト

2. **GoogleOAuth2Client ラッパー**（3-4時間）
   - `GoogleOAuth2Client` 構造体実装
   - `build_auth_url()` メソッド実装
   - `exchange_code()` メソッド実装
   - ユニットテスト

3. **ヘルパー関数**（2-3時間）
   - `parse_callback_url()` - リダイレクトURLパース
   - `PkceStorage` trait定義
   - ユニットテスト

4. **統合とテスト**（3-4時間）
   - `examples/basic_auth/` サンプル作成
   - 実際のGoogle OAuth2で動作確認
   - E2Eテスト手順書作成

## スコープ

### 含む ✅

- Google OAuth2の認可コードフロー（Authorization Code Flow）実装
- Google定数（エンドポイント、スコープ）定義
- `GoogleOAuth2Client` 構造体とヘルパー関数
- ユニットテストスイート（80%以上のカバレッジ目標）
- サンプルアプリケーション
- README更新と基本的なドキュメント

### 含まない ❌

- サーバー間認証（Service Account Flow）→ Phase 1.5で実装
- トークンリフレッシュ機能 → Phase 2で実装
- トークンストレージ実装 → Phase 2で実装
- ID Token署名検証 → Phase 3で実装
- OpenID Connect完全対応 → Phase 3で実装

## 影響範囲

### 変更対象ファイル

**新規作成:**
- `lib/google_constants.mbt` - Google定数定義
- `lib/google_client.mbt` - GoogleOAuth2Client実装
- `lib/google_helpers.mbt` - ヘルパー関数
- `lib/google_constants_test.mbt` - テスト
- `lib/google_client_test.mbt` - テスト
- `lib/google_helpers_test.mbt` - テスト
- `examples/basic_auth/main.mbt` - サンプルアプリ
- `examples/basic_auth/moon.pkg` - パッケージ定義

**変更対象:**
- `moon.mod.json` - 依存関係確認（既に `ryota0624/oauth2` 追加済み）
- `README.md` - 使用方法記載
- `docs/` - ドキュメント整備

### 他の機能への影響

- **低リスク**: Phase 1は新規追加のみで、既存機能に影響なし
- Phase 2（トークン管理）で `TokenManager` が追加される予定
- Phase 1.5（サーバー間認証）で別のモジュールが追加される予定

## 技術的な決定事項

### ライブラリの採択

**採用:** `ryota0624/oauth2` v0.1.2

**理由:**
- OAuth2プロトコル実装完了（テストカバレッジ100以上）
- PKCE、CSRF対応済み
- アクティブに開発中
- 品質が高い（コード review済み）

**参考:** `docs/revised_plan_with_oauth2_lib.md` - 詳細な比較分析

### テスト戦略

- **ユニットテスト**: 各モジュール独立でテスト（80%以上カバレッジ）
- **統合テスト**: モックHTTPサーバー利用
- **E2Eテスト**: 実際のGoogle OAuth2で手動検証（README記載）

### コード品質基準

- MoonBit format: `moon fmt` で統一
- インターフェース更新: `moon info` で確認
- テスト実行: `moon test` で全テスト実行可能
- カバレッジ: `moon coverage analyze` で80%以上確認

## 成功基準

Phase 1 完了時に以下をすべて満たす状態：

1. **コンパイル**: `moon info && moon fmt` 実行可能
2. **テスト**: `moon test` で全テスト成功 ✅
3. **カバレッジ**: 80%以上
4. **動作確認**: Google実APIとのE2E動作確認済み
5. **ドキュメント**: README、使用例、APIドキュメント完備
6. **Git**: コミットログに変更の意図を明確に記載

## 見積もり

| 項目 | 工数 | 備考 |
|---|---|---|
| Google定数定義 | 2-3時間 | 実装+テスト |
| GoogleOAuth2Client | 3-4時間 | 実装+テスト |
| ヘルパー関数 | 2-3時間 | 実装+テスト |
| 統合とテスト | 3-4時間 | サンプル+E2E準備 |
| **合計** | **10-14時間** | **1-2日** |

## 参考資料

- `docs/revised_plan_with_oauth2_lib.md` - 詳細な実装計画と見直し内容
- `docs/features.md` - 機能仕様
- `Todo.md` - 全体的なプロジェクトTodo
- ryota0624/oauth2ライブラリドキュメント（mooncakes.io）
