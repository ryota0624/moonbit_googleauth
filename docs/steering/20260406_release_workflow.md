# Steering: リリースワークフローの実装

## 目的・背景
moonbit_googleauthパッケージのリリースプロセスを自動化するため、GitHub Actionsワークフローを導入する。
参考: https://github.com/ryota0624/moonbit_k6/blob/main/.github/workflows/release.yml

## ゴール
- mainブランチへのpush時にリリースPRを自動作成/更新
- リリースPRマージ時にGitHubリリース作成 + mooncakesレジストリへのpublish
- moon-releaseツールを使用した自動バージョン管理

## アプローチ
- moonbit_k6の既存ワークフローをベースにそのまま適用
- moon-release 0.3を使用
- 2ジョブ構成: release-pr + release

## スコープ
- 含む: `.github/workflows/release.yml` の作成
- 含まない: moon-releaseの設定カスタマイズ、MOONCAKES_TOKEN等のsecrets設定

## 影響範囲
- `.github/workflows/release.yml` の新規追加のみ
- 既存コードへの変更なし
