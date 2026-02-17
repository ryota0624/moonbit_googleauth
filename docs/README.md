# Google OAuth2認証ライブラリ 調査・設計ドキュメント

## 📋 ドキュメント一覧

このディレクトリには、MoonBit用Google OAuth2認証ライブラリの実装に向けた調査と設計ドキュメントが含まれています。

### 1. [調査レポート](investigation.md)

**内容:**
- Google OAuth2認証の基本フローと仕様
- 参考ライブラリの分析（Rust oauth2-rs等）
- MoonBitで利用可能なライブラリ（mio、moonbitlang/async）
- 推奨実装アプローチ

**対象読者:** 実装前に全体像を把握したい開発者

### 2. [機能仕様書](features.md)

**内容:**
- 実装すべき全機能の詳細定義
- コア機能（Config管理、認可フロー、トークン管理）
- 高度な機能（PKCE、トークンストレージ）
- Phase別の実装優先度

**対象読者:** 具体的な機能を実装する開発者

### 3. [実装計画](implementation_plan.md)

**内容:**
- Phase 1-3の段階的実装計画
- 詳細なステップバイステップの実装順序
- ファイル構成とコンポーネント設計
- 各フェーズの推定工数とマイルストーン

**対象読者:** プロジェクトマネージャー、実装担当者

### 4. [テスト戦略](testing_strategy.md)

**内容:**
- ユニット/統合/E2Eテストの方針
- 具体的なテストケースとコード例
- モックサーバーの設計
- CI/CD統合とセキュリティテスト

**対象読者:** テスト担当者、QAエンジニア

## 🎯 プロジェクト概要

### 目標

MoonBit言語でGoogle API認証を実現する、型安全で使いやすいOAuth2ライブラリを実装します。

### 主要な特徴

1. **型安全性** - Rustのoauth2-rsを参考に、型システムを活用した誤用防止
2. **段階的実装** - MVP → トークン管理 → セキュリティ強化の3フェーズ
3. **セキュリティファースト** - CSRF対策、PKCE対応、HTTPS強制
4. **使いやすいAPI** - ビルダーパターンと明確なエラーハンドリング

### 技術スタック

| 用途 | 技術 |
|---|---|
| 言語 | MoonBit |
| HTTPクライアント | oboard/mio |
| JSON処理 | MoonBitビルトイン |
| テスト | MoonBit標準テストフレームワーク |

## ⚡ 重要な更新: 実装計画の大幅な見直し

**既存のMoonBit OAuth2ライブラリ（[ryota0624/oauth2](https://mooncakes.io/docs/ryota0624/oauth2)）を発見!**

詳細な分析結果: [revised_plan_with_oauth2_lib.md](revised_plan_with_oauth2_lib.md)

### 主な変更点

| 項目 | 当初計画 | 見直し後 | 改善 |
|---|---|---|---|
| **総推定期間** | 2-3週間 | **3-5日** | **80%短縮** |
| **実装すべきコード** | ~2000行 | **~300行** | **85%削減** |
| **焦点** | OAuth2プロトコル実装 | **Google特有の機能** | - |

### 既存ライブラリ ryota0624/oauth2 の機能

✅ **実装済み:**
- Authorization Code Flow with PKCE
- Client Credentials Flow
- Password Grant Flow
- Refresh Token サポート
- CSRF保護（暗号学的に安全）
- 型安全なAPI
- クロスプラットフォーム（Native/JS）
- 包括的なテストスイート（100以上）

❌ **未実装（実装が必要）:**
- Google特有の定数・スコープ定義
- ラッパーAPI
- トークン自動管理
- Google特有のドキュメント

## 📊 見直し後の実装計画サマリー

### Phase 1: Google OAuth2 ラッパー（推定工数: 1-2日）

**目標:** ryota0624/oauth2を使ったGoogle特有の実装

**成果物:**
- Google定数定義（エンドポイント、スコープ）
- GoogleOAuth2Client ラッパー（ユーザー認証用）
- ヘルパー関数
- サンプルアプリケーション

### Phase 1.5: Server-to-Server認証（推定工数: 1.5-2.5日）⚠️ **工数見直し**

**目標:** サーバー間API呼び出し用の認証実装

**成果物:**
- Client Credentials Flow ラッパー（既存ライブラリ活用）
- **Application Default Credentials (ADC)** ⭐ **NEW - 必須**
- **Metadata Server認証** ⭐ **NEW - 必須**
- **自動認証検出** ⭐ **NEW - 推奨**
- Service Account JWT（条件付き: RSA署名ライブラリが利用可能な場合）

詳細:
- [server_to_server_auth.md](server_to_server_auth.md)
- [application_default_credentials.md](application_default_credentials.md) ⭐ **NEW**

### Phase 2: 高度な機能（推定工数: 0.5-1日）

**目標:** 利便性機能の追加

**成果物:**
- トークン管理（有効期限チェック）
- トークンストレージ抽象化
- 自動リフレッシュ機能

### Phase 3（オプション）: OpenID Connect（推定工数: 1-2日）

**目標:** ID Token検証とUserInfo連携

**成果物:**
- ID Token署名検証
- UserInfo endpoint統合
- クレーム検証

## 🗓️ 更新されたマイルストーン

| マイルストーン | 期限 | 成果物 |
|---|---|---|
| M1: ラッパー実装 | 実装開始から1-2日 | Google OAuth2基本動作 |
| M2: 高度な機能 | M1から0.5-1日 | トークン管理・ストレージ |
| M3: ドキュメント完備 | M2から0.5-1日 | 完全なドキュメント |
| M4: 1.0リリース | M3から0.5日 | プロダクション対応 |

**総推定期間:** 約3-5日（当初計画の約20%）

## 📚 参考資料

### 公式ドキュメント
- [Using OAuth 2.0 to Access Google APIs](https://developers.google.com/identity/protocols/oauth2)
- [Using OAuth 2.0 for Web Server Applications](https://developers.google.com/identity/protocols/oauth2/web-server)
- [OAuth 2.0 for Client-side Web Applications](https://developers.google.com/identity/protocols/oauth2/javascript-implicit-flow)

### 参考実装
- [oauth2-rs (Rust)](https://docs.rs/oauth2/latest/oauth2/) - 型安全な設計の参考
- [OAuth Libraries for Rust](https://oauth.net/code/rust/)
- [Google OAuth2 in Rust Guide](https://codevoweb.com/how-to-implement-google-oauth2-in-rust/)

### MoonBit関連
- [MoonBit公式サイト](https://www.moonbitlang.com/)
- [MoonBit Documentation](https://docs.moonbitlang.com/)
- [mio - HTTP networking package](https://github.com/oboard/mio)
- [moonbitlang/async](https://www.moonbitlang.com/blog/moonbit-async-code-agent)
- [awesome-moonbit](https://github.com/moonbitlang/awesome-moonbit)

## 🚀 次のステップ

### 1. 環境セットアップ
- MoonBit開発環境の確認
- mioライブラリの依存関係追加
- プロジェクト構造の整備

### 2. Phase 1 実装開始
- [実装計画](implementation_plan.md) の Phase 1 Step 1 から開始
- 基本型定義（types.mbt, errors.mbt）
- ユニットテストの並行作成

### 3. Google Cloud Console設定
- プロジェクト作成
- OAuth 2.0クライアントIDの作成
- テスト用認証情報の取得

## 💡 設計の要点

### 型安全性

```moonbit
// 不正な使用をコンパイル時に防ぐ
struct OAuth2Config { ... }  // ビルダーで段階的に構築
struct Token { ... }          // 有効期限を型で管理
enum OAuth2Error { ... }      // 明示的なエラー型
```

### エラーハンドリング

```moonbit
// Result型による明示的なエラー処理
fn exchange_code_for_token(
  config: OAuth2Config,
  code: String
) -> Result[TokenResponse, OAuth2Error]
```

### セキュリティ

- state パラメータによるCSRF対策
- PKCEによる認可コード横取り対策
- HTTPSの強制（localhost除く）
- トークンの安全な管理

## 📝 貢献ガイドライン

### 開発フロー
1. 機能ブランチを作成
2. ユニットテストを先に書く（TDD）
3. 実装
4. テストが全て通ることを確認
5. PRを作成

### コードスタイル
- MoonBitの標準フォーマッターを使用
- 関数には明確なドキュメントコメント
- エラーケースを常に考慮

### テスト要件
- 新機能にはユニットテスト必須
- カバレッジ80%以上を維持
- E2Eテストは手動で実施

## 📞 お問い合わせ

- Issues: プロジェクトのGitHub Issues
- Discussions: 設計や実装に関する議論

---

**最終更新:** 2026-02-17
**バージョン:** 0.1.0（調査・設計フェーズ）
