# Steering: Phase 2 - 高度な機能実装

## 目的・背景

Phase 1 および Phase 1.5 で Google OAuth2 認証の基盤が完成しました。
Phase 2 では、トークンのライフサイクル管理、永続化、及び高レベルAPIを実装し、開発者にとって使いやすいインターフェースを提供します。

## ゴール

1. **トークン有効期限管理**: TokenManager で有効期限の追跡と更新判定を実装
2. **トークンストレージ抽象化**: TokenStorage trait でプラグイン可能な保存機構を定義
3. **高レベルAPI**: GoogleApiClient で自動トークンリフレッシュ機能を提供
4. **テスト完全性**: 既存 44 テスト全てパスの状態を維持しながら、新たに ~21 テスト追加

## アプローチ

- **不変関数型スタイル**: MoonBit の慣例に従い、状態更新は新しいインスタンス返却で実現
- **オフセットベース時間管理**: Phase 3 での実システム時刻導入まで、相対時刻オフセットを使用
- **段階的実装**: TokenManager → TokenStorage → GoogleApiClient の順で実装
- **テスト駆動開発**: 各機能の実装と同時にテストを作成

## スコープ

**含む:**
- TokenManager 構造体と有効期限判定メソッド
- TokenStorage トレイト定義（InMemory, File スタブ実装）
- GoogleApiClient 高レベル API
- ユニットテスト (~21 件)
- TokenStorageError エラー型追加

**含まない:**
- ファイル I/O の実装（Phase 3 対象）
- 実システム時刻の使用（Phase 3 対象）
- OpenID Connect 完全対応（Phase 3 対象）

## 影響範囲

**新規作成:**
- `lib/token_manager.mbt`, `lib/token_manager_test.mbt`
- `lib/token_storage.mbt`, `lib/token_storage_test.mbt`
- `lib/google_api_client.mbt`, `lib/google_api_client_test.mbt`

**修正:**
- `lib/service_account_types.mbt`: TokenStorageError enum 追加

**更新:**
- `Todo.md`: Phase 2 チェックボックスの更新
- `pkg.generated.mbti`: インターフェース再生成

## 実装順序

1. `service_account_types.mbt` を修正: `TokenStorageError` enum 追加
2. `lib/token_manager.mbt` + テスト実装
3. `lib/token_storage.mbt` + テスト実装
4. `lib/google_api_client.mbt` + テスト実装
5. `moon fmt && moon info` で整形・インターフェース更新
6. 全テスト実行確認
7. Todo.md 更新
8. Git commit

## 成功基準

- [ ] `moon test` で全テストパス（~65 テスト）
- [ ] 新規追加テスト: ~21 件
- [ ] `moon fmt lib` で形式的な問題なし
- [ ] `moon info lib` で .mbti 更新完了
- [ ] 既存機能への回帰なし（Phase 1.5 テスト全てパス）

## リスク管理

- **時刻管理**: オフセットベース設計により、Phase 3 での移行が容易
- **ストレージ抽象化**: Trait ベースで実装の追加が簡単
- **テストカバレッジ**: 全 public API に対するテストを実装

## 参考資料

- `docs/revised_plan_with_oauth2_lib.md`: Phase 1 実装計画
- `docs/server_to_server_auth.md`: Phase 1.5 設計
- Previous completion reports in `docs/completed/`
